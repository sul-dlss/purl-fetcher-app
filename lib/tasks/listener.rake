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
end
