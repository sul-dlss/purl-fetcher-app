require 'fileutils'
require 'listen'

namespace :listener do
  PIDFILE = 'run/listener.pid'

  desc 'Start the listener'
  task :start, [:purl_document_path] => :environment do |_t, args|
    puts "Starting listener"
    args.with_defaults(purl_document_path: PurlFetcher::Application.config.app_config['purl_document_path'])
    listener = Listen.to(args[:purl_document_path], force_polling: true, only: /public$/) do |modified, added, removed|
      IndexingLogger.debug { "modified: #{modified}" }
      IndexingLogger.debug { "added: #{added}" }
      IndexingLogger.debug { "removed: #{removed}" }
      [added, modified].flatten.each do |public_filename|
        Purl.index(File.dirname(public_filename))
        IndexingLogger.info("Indexed #{public_filename}")
      end
      removed.each do |public_filename|
        IndexingLogger.info("Ignoring deleted file #{public_filename}")
      end
    end
    listener.start
    Process.daemon(true)
    File.open(PIDFILE, 'w') {|f| f << $$ }
    sleep
  end

  desc 'Stop the listener'
  task :stop do
    puts "Stopping listener"
    if File.size?(PIDFILE)
      pid = File.read(PIDFILE)
      begin
        Process.kill('TERM', pid.to_i)
      rescue Errno::ESRCH
        FileUtils.rm_f(PIDFILE)
      end
    end
  end

  desc 'Restart the listener'
  task :restart => [:stop, :start]
end
