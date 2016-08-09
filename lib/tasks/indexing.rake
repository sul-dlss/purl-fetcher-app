require 'benchmark'
require 'fileutils'
require 'logger'
require 'purl_finder'

desc 'Full reindex of all purls'
task :full_reindex => :environment do |_t, args|
  start_time = Time.zone.now
  result = PurlFinder.new.full_reindex
  IndexingLogger.info("Running of rake task 'full_reindex' at #{start_time} returned a result of #{result.inspect}")
end

desc 'Index objects modified since the last indexing job started'
task :index_changes_since_last_run => :environment do |_t, args|
  start_time = Time.zone.now
  result = PurlFinder.new.index_since_last_run
  IndexingLogger.info("Running of rake task 'index_changes_since_last_run' at #{start_time} returned a result of #{result.inspect}")
end

desc 'Index objects deleted in last n minutes. Defaults to 1 hour'
task :index_deletes, [:mins_ago] => :environment do |_t, args|
  args.with_defaults(mins_ago: 60)
  start_time = Time.zone.now
  result = PurlFinder.new.remove_deleted(mins_ago: args[:mins_ago] + 1) # adding one minute for slop
  IndexingLogger.info("Running of the rake task 'index_deletes' #{args[:mins_ago]} mins at #{start_time} returned a result of #{result.inspect}")
end

desc 'Search for all objects deleted within the last 5 minutes and update database'
task :process_all_deletes_in_last_five_minutes => :environment do
  Rake::Task[:index_deletes].invoke(5)
end

desc 'Index a specific set of PURLs given a file pointing to the public XML files'
task :index_from_file, [:filename] => :environment do |_t, args|
  unless args.filename.present? && File.size?(args.filename)
    fail ArgumentError, "Requires a filename that contains the public XML file paths"
  end
  n = 0
  elapsed_time = Benchmark.realtime do
    IO.foreach(args.filename) do |line|
      path = line.strip
      # Purl.index takes _directory_ paths, not public XML filenames
      path = File.dirname(path) if File.file?(path)
      if File.file?(File.join(path, 'public'))
        Purl.index(path)
        IndexingLogger.info("Indexed #{path}")
        n += 1
      else
        IndexingLogger.error("Missing public file in #{path}. Skipping indexing")
      end
    end
  end
  IndexingLogger.info("Indexed #{n} items from #{args.filename} in #{elapsed_time.ceil} seconds")
end
