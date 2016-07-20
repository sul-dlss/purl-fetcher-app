require 'fileutils'
require 'logger'

desc 'Index objects modified in last n minutes. Defaults to 1 hour'
task :index_changes, [:mins_ago, :logfile] => :environment do |_t, args|
  args.with_defaults(mins_ago: 60, logfile: 'log/indexing_rake_task.log')
  start_time = Time.zone.now
  result = IndexerController.new.index_all_modified_objects(mins_ago: args[:mins_ago] + 1) # adding one minute for slop

  # ensure log folder is created
  path = File.dirname(args[:logfile])
  FileUtils.mkdir_p path unless File.directory?(path)

  # log result
  indexing_log = Logger.new(args[:logfile])
  indexing_log.info("Running of rake task 'index_changes' for #{args[:mins_ago]} mins ago at #{start_time} returned a result of #{result}")
end

desc 'Search for all objects modified within the last 5 minutes and add index them into to solr'
task :index_changes_in_last_five_minutes => :environment do
  Rake::Task[:index_changes].invoke(5)
end

desc 'Search for all objects modified within the last 15 minutes and add index them into to solr'
task :index_changes_in_last_fifteen_minutes => :environment do
  Rake::Task[:index_changes].invoke(15)
end

desc 'Search for all objects modified within the last 2 hours and add index them into to solr'
task :index_changes_in_last_two_hours => :environment do
  Rake::Task[:index_changes].invoke(2*60)
end

desc 'Search for all objects modified since the start of the Unix Epoch and add index them into to solr'
task :index_since_beginning_of_unix_time => :environment do
  Rake::Task[:index_changes].invoke((Time.zone.now.to_i / 60.0).ceil)
end

desc 'Search for all objects deleted within the last 5 minutes and update solr'
task :process_all_deletes_in_last_five_minutes => :environment do
  start_time = Time.zone.now
  indexer = IndexerController.new
  result = indexer.remove_deleted_objects_from_solr(mins_ago: 6) # adding one minute for slop
  delete_log = Logger.new('log/delete_rake_task.log')
  delete_log.info("Running of the rake task process_all_deletes_in_last_five_minutes at #{start_time} returned a result of #{result}")
end
