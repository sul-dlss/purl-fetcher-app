require 'fileutils'
require 'logger'
require 'indexer'

desc 'Full reindex of all purls'
task :full_reindex => :environment do |_t, args|
  start_time = Time.zone.now
  result = Indexer.new.full_reindex
  IndexingLogger.info("Running of rake task 'full_reindex' at #{start_time} returned a result of #{result.inspect}")
end

desc 'Index objects modified since the last indexing job started'
task :index_changes_since_last_run => :environment do |_t, args|
  start_time = Time.zone.now
  result = Indexer.new.index_since_last_run
  IndexingLogger.info("Running of rake task 'index_changes_since_last_run' at #{start_time} returned a result of #{result.inspect}")
end

desc 'Index objects deleted in last n minutes. Defaults to 1 hour'
task :index_deletes, [:mins_ago] => :environment do |_t, args|
  args.with_defaults(mins_ago: 60)
  start_time = Time.zone.now
  result = Indexer.new.remove_deleted(mins_ago: args[:mins_ago] + 1) # adding one minute for slop
  IndexingLogger.info("Running of the rake task 'index_deletes' #{args[:mins_ago]} mins at #{start_time} returned a result of #{result.inspect}")
end

desc 'Search for all objects deleted within the last 5 minutes and update solr'
task :process_all_deletes_in_last_five_minutes => :environment do
  Rake::Task[:index_deletes].invoke(5)
end
