require 'benchmark'
require 'purl_finder'

namespace :find do
  desc 'Scan filesystem for all PURL objects (both adds/changes and deletes) - optionally, only last n minutes.'
  task :all, [:mins_ago] => :environment do |_t, args|
    args.with_defaults(mins_ago: nil)
    Rake::Task['find:changes'].invoke(args[:mins_ago])
    Rake::Task['find:deletes'].invoke(args[:mins_ago])
  end

  desc 'Scan filesystem for PURL objects adds/changes - optionally, only last n minutes.'
  task :changes, [:mins_ago] => :environment do |_t, args|
    args.with_defaults(mins_ago: nil)

    pid_file = File.expand_path('tmp/pids/find_changes_task.pid', Rails.root)

    if File.exist? pid_file
      puts "PID file (#{pid_file}) exists. Job has not finished yet."
      break
    end

    File.open(pid_file, 'w') do |f|
      f.puts Process.pid
    end

    begin
      elapsed_time = Benchmark.realtime do
        PurlFinder.new.find_and_save(mins_ago: args[:mins_ago])
      end
      UpdatingLogger.info("Ran 'find:changes[#{args[:mins_ago]}]' in #{elapsed_time.ceil} seconds")
    ensure
      File.delete pid_file
    end
  end

  desc 'Scan filesystem PURL objects deletes - optionally, only last n minutes.'
  task :deletes, [:mins_ago] => :environment do |_t, args|
    args.with_defaults(mins_ago: nil)
    elapsed_time = Benchmark.realtime do
      PurlFinder.new.remove_deleted(mins_ago: args[:mins_ago])
    end
    UpdatingLogger.info("Ran 'find:deletes[#{args[:mins_ago]}]' in #{elapsed_time.ceil} seconds")
  end
end
