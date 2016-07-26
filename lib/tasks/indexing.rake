require 'fileutils'
require 'logger'
require 'indexer'

desc 'Index objects modified since the last indexing job started'
task :index_changes_since_last_run => :environment do |_t, args|
  start_time = Time.zone.now
  result = Indexer.new.index_since_last_run
  Logger.new('log/indexing.log').info("Running of rake task 'index_changes_since_last_run' at #{start_time} returned a result of #{result.inspect}")
end

desc 'Index objects modified in last n minutes. Defaults to 1 hour'
task :index_changes, [:mins_ago] => :environment do |_t, args|
  args.with_defaults(mins_ago: 60)
  start_time = Time.zone.now
  result = Indexer.new.index_all_modified_objects(mins_ago: args[:mins_ago] + 1) # adding one minute for slop
  Logger.new('log/indexing.log').info("Running of rake task 'index_changes' for #{args[:mins_ago]} mins ago at #{start_time} returned a result of #{result.inspect}")
end

desc 'Search for all objects modified since the start of the Unix Epoch and add index them into to solr'
task :index_since_beginning_of_unix_time => :environment do
  Rake::Task[:index_changes].invoke((Time.zone.now.to_i / 60.0).ceil)
end

desc 'Index objects deleted in last n minutes. Defaults to 1 hour'
task :index_deletes, [:mins_ago] => :environment do |_t, args|
  args.with_defaults(mins_ago: 60)
  start_time = Time.zone.now
  result = Indexer.new.remove_deleted_objects_from_solr(mins_ago: args[:mins_ago] + 1) # adding one minute for slop
  Logger.new('log/indexing.log').info("Running of the rake task 'index_deletes' #{args[:mins_ago]} mins at #{start_time} returned a result of #{result.inspect}")
end

desc 'Search for all objects deleted within the last 5 minutes and update solr'
task :process_all_deletes_in_last_five_minutes => :environment do
  Rake::Task[:index_deletes].invoke(5)
end
