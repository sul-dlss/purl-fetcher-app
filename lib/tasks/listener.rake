require 'purl_listener'

namespace :listener do
  namespace :log do
    desc 'Clear log data'
    task :clear do
      Rake::Task['listener:stop'].invoke
      ListenerLog.destroy_all
    end
  end

  desc 'Restart the listener if it is down'
  task :restart_if_down => :environment do |_t, args|
    begin
      listener = PurlListener.new
      listener.start unless listener.running?
    rescue SignalException => e
      Honeybadger.notify(e)
      puts "Listener status could not be checked or it could not be restarted: #{e.message}"
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

  namespace :recent_changes do
    desc 'Process all recent_changes touch files. Requires Listener to be running.'
    task :process => :environment do
      listener = PurlListener.new
      if listener.running?
        system("find #{listener.path} -type f | xargs touch")
      else
        puts "Listener is not running"
      end
    end
  end
end
