require 'purl_listener'

namespace :listener do
  namespace :log do
    desc 'Clear log data'
    task :clear do
      Rake::Task['listener:stop'].invoke
      ListenerLog.destroy_all
    end
  end

  desc 'Start the listener'
  task :start => :environment do |_t, args|
    begin
      PurlListener.new.start
    rescue SignalException => e
      Honeybadger.notify(e)
      puts "Listener stopped via signal #{e.message}"
    end
  end

  desc 'Stop the listener'
  task :stop => :environment do
    PurlListener.new.stop
  end

  desc 'Status of the listener'
  task :status => :environment do
    listener = PurlListener.new
    if listener.running?
      system("ps -ww -F -p #{listener.pid}")
    else
      puts "Listener is not running"
    end
  end

  desc 'Restart the listener'
  task :restart => [:stop, :start]

  desc 'Touch all the recent_changes files'
  task :touch_all => :environment do
    listener = PurlListener.new
    puts "Processing #{listener.path}"
    Dir.glob(File.join(listener.path, '*')) do |fn|
      puts "Touching #{fn}"
      FileUtils.touch(fn, { :nocreate => true })
    end
  end
end
