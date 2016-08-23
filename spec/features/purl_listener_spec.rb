require 'rails_helper'

describe PurlListener do
  context '.initialize' do
    it 'using the correct path' do
      expect(subject.path).to eq Pathname(PurlFetcher::Application.config.app_config['listener_path'])
    end
    it 'using the correct pid_file' do
      expect(subject.pid_file).to eq Pathname(PurlFetcher::Application.config.app_config['listener_pid_file'])
    end
    it 'using the correct logger' do
      expect(subject.logger).to eq IndexingLogger
    end
    it 'has an event handler' do
      expect(subject.event_handler).to be_an Proc
    end
  end

  context '.start' do
    it 'starts listening for the very first time' do
      expect(subject.logger).to receive(:info).with(/Starting/)

      # check that we are indeed running for the first time
      expect(ListenerLog).to receive(:minutes_since_last_active).and_return(nil)
      expect(subject.logger).to receive(:warn).with(/listener has never done any work/)
      expect(subject).not_to receive(:run_find_all)

      # check that the listener is started
      expect(subject).to receive(:listen_for_changes)
      expect(subject).to receive(:remove_pid_file)
      subject.start
    end

    it 'runs delta rake if listener was previously active' do
      expect(subject.logger).to receive(:info).with(/Starting/)

      # check that we are running for the nth time
      expect(ListenerLog).to receive(:minutes_since_last_active).and_return(123)
      expect(subject).to receive(:run_find_all).with(123)

      # check that the listener is started
      expect(subject).to receive(:listen_for_changes)
      subject.start
    end

    it 'cleans up pid file on Exception' do
      expect(subject.logger).to receive(:info).with(/Starting/)
      expect(subject).to receive(:run_delta)
      expect(subject).to receive(:listen_for_changes).and_raise(SignalException.new('TERM'))
      expect(subject).to receive(:remove_pid_file)
      expect { subject.start }.to raise_error(SignalException)
    end
  end

  context '.stop' do
    before do
      expect(subject.logger).to receive(:info).with(/Stopping/)
    end

    it 'does nothing if the listener is not running' do
      expect(subject).to receive(:'running?').and_return(false)
      subject.stop
    end
    it 'sends signal if the listener is running' do
      expect(subject).to receive(:'running?').and_return(true)
      expect(subject).to receive(:pid).and_return(123)
      expect(Process).to receive(:kill).with(/TERM/, 123)
      subject.stop
    end
    it 'cleans up pid_file the pid from the file is no longer a process' do
      expect(subject).to receive(:'running?').and_return(true)
      expect(subject).to receive(:pid).and_return(123)
      expect(Process).to receive(:kill).with(/TERM/, 123).and_raise(Errno::ESRCH)
      expect(subject.pid_file).to receive(:delete)
      subject.stop
    end
    it 'cleans up orphaned pid_file' do
      expect(subject).to receive(:'running?').and_return(false)
      expect(subject.pid_file).to receive(:delete).and_raise(Errno::ENOENT)
      subject.stop
    end
  end

  context '.running?' do
    it 'returns false when not running' do
      expect(subject.running?).to be_falsey
    end
    it 'returns true when running' do
      subject.instance_variable_set(:@pid, $PID)
      expect(subject.running?).to be_truthy
    end
    it 'returns false when pid is set but not running' do
      subject.instance_variable_set(:@pid, $PID)
      expect(Process).to receive(:kill).with(0, $PID).and_raise(Errno::ESRCH)
      expect(subject.running?).to be_falsey
    end
  end

  context '.pid' do
    it 'returns nil when no pid_file' do
      expect(subject.pid_file).to receive(:read).and_raise(Errno::ENOENT.new)
      expect(subject.pid).to be_nil
    end
    it 'returns value of pid_file' do
      expect(subject.pid_file).to receive(:read).and_return('123')
      expect(subject.pid).to eq 123
    end
  end

  context '.listen_for_changes' do
    before do
      allow_any_instance_of(Object).to receive(:sleep).with(no_args).and_raise(SignalException.new('TERM'))
    end

    it 'calls Listen.to and daemonize into sleep-based infinite loop' do
      expect(subject.logger).to receive(:info).with(/Listening to/)
      expect(Listen).to receive(:to).and_return(double(start: nil))
      expect(Process).to receive(:daemon)
      expect(subject.pid_file).to receive(:write).with($PROCESS_ID.to_s)
      expect(Process).to receive(:setproctitle).with(/purl-fetcher-listener/)
      expect(ListenerLog).to receive(:create)
      expect { subject.send(:listen_for_changes) }.to raise_error(SignalException)
    end
  end

  context 'processing files' do
    let(:druid) { 'aa111bb2222' }
    let(:fn) { Pathname("/no/where/#{druid}") }
    before do
      ListenerLog.create(process_id: $PID, started_at: Time.current - 1)
    end

    context '.process_event' do
      it 'parses a valid druid from the filename and mark active' do
        expect(subject).to receive(:process_druid_file).with(fn, druid)
        expect(subject.logger).to receive(:info).with(/Processed/)
        subject.send(:process_event, fn)
        expect(ListenerLog.current.active_at).to be_an Time
      end
      it 'logs exceptions correctly' do
        expect(subject).to receive(:process_druid_file).and_raise(StandardError.new)
        expect(subject.logger).to receive(:error).with(/Cannot process/)
        expect(Honeybadger).to receive(:notify)
        subject.send(:process_event, fn)
      end
      it 'skips filenames that are not druids' do
        expect(subject).not_to receive(:process_druid_file)
        expect(subject.logger).to receive(:warn).with(/Ignoring miscellaneous/)
        subject.send(:process_event, Pathname('/no/where/not_a_druid'))
      end
    end
    context '.process_druid_file' do
      it 'parses the druid from the filename' do
        expect(fn).to receive(:rename).with("#{fn}.lock")
        expect(PurlFinder).to receive(:new).and_return(double(purl_path: '/some/place'))
        expect(Purl).to receive(:save_from_public_xml)
        expect_any_instance_of(Pathname).to receive(:delete)
        subject.send(:process_druid_file, fn, druid)
      end
    end
  end

  context '.run_find_all' do
    it 'runs a rake task' do
      allow_any_instance_of(Object).to receive(:system).with(/rake find:all\[1\].*&$/)
      subject.send(:run_find_all, 1)
    end
  end

  context '.event_handler' do
    it 'processes adds' do
      expect(subject).to receive(:process_event)
      subject.event_handler.call([], ['abc'], [])
    end
    it 'processes modified' do
      expect(subject).to receive(:process_event)
      subject.event_handler.call(['abc'], [], [])
    end
    it 'ignores deletes' do
      expect(subject.logger).to receive(:debug).with(/Ignoring/)
      subject.event_handler.call([], [], ['abc'])
    end
  end
end
