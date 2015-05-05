require 'logger'

desc "Search for all objects modified within the last 5 minutes and add index them into to solr"
task :index_changes_in_last_five_minutes => :environment do
  start_time = Time.now
  indexer = IndexerController.new
  result = indexer.index_all_modified_objects(mins_ago: 6) #adding one minute for slop
  indexing_log = Logger.new('log/indexing_rake_task.log')
  indexing_log.info("Running of rake task index_changes_in_last_five_minutes at #{start_time} returned a result of #{result}")
end

desc "Search for all objects modified since the start of the Unix Epoch and add index them into to solr"
task :index_since_beginning_of_unix_time => :environment do
  start_time = Time.now
  minutes_since_epoch = (Time.now.to_i/60.0).ceil
  indexer = IndexerController.new
  result = indexer.index_all_modified_objects(mins_ago: minutes_since_epoch + 1) #adding one minute for slop
  indexing_log = Logger.new('log/indexing_rake_task.log')
  indexing_log.info("Running of rake task index_since_beginning_of_unix_time at #{start_time} returned a result of #{result}")
end

dec "Search for all objects deleted within the last 5 minutes and update solr"
task :process_all_deletes_in_last_five_minutes => :environment do
  start_time = Time.now
  indexer = IndexerController.new
  result = indexer.remove_deleted_objects_from_solr(mins_ago: 6) #adding one minute for slop
  delete_log = Logger.new("log/delete_rake_task.log")
  delete_log.info("Running of the rake task process_all_deletes_in_last_five_minutes at #{start_time} returned a result of #{result}")
end