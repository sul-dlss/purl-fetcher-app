class RunLog < ActiveRecord::Base

  CRASHED_PRUNE_TIME_IN_DAYS = 2 # after this many days, any job which has not yet ended is assumed to have crashed and is removed

  before_destroy :remove_output_file

  # check to see if there is a job currently running according to the logs...this is a job with no end time yet
  def self.currently_running?
    prune_crashed_rows
    where(ended: nil).order('ended DESC').size == 1
  end

  # the total time of the last run in minutes rounded up
  def self.last_run_time_in_minutes
    last_row = last_completed_run
    ((last_row.ended - last_row.started) / 60.0).ceil if last_row
  end

  # how many minutes ago the last run completed rounded up
  def self.minutes_since_last_run_ended
    prune_crashed_rows
    last_row = last_completed_run
    end_time = last_row ? last_row.ended : Time.zone.at(0)
    ((Time.zone.now - end_time) / 60.0).ceil
  end

  # how many minutes ago the last run started, useful for determining how far back to start for next run, rounded up
  def self.minutes_since_last_run_started
    prune_crashed_rows
    last_row = last_completed_run
    start_time = last_row ? last_row.started : Time.zone.at(0)
    ((Time.zone.now - start_time) / 60.0).ceil
  end

  # the last completed run, returned as a model object
  def self.last_completed_run
    order('ended DESC').find_by('ended IS NOT NULL')
  end

  # remove all rows with no end time that were started more than CRASHED_PRUNE_TIME_IN_DAYS days ago (i.e. the job was started and must have died without completing the entry)
  def self.prune_crashed_rows
    where('updated_at < ?', CRASHED_PRUNE_TIME_IN_DAYS.days.ago).where('ended IS NULL').find_each(&:destroy)
  end

  # prune the logs by removing older completed jobs
  def self.prune
    prune_crashed_rows
    where('updated_at < ?', 6.months.ago).find_each(&:destroy) # anything older than 6 months
    where(total_druids: 0).where('updated_at < ?', 1.day.ago).find_each(&:destroy) # anything older than 1 day with no activity
  end

  # remove all completed logs
  def self.prune_all
    where('ended IS NOT NULL').find_each(&:destroy) # anything that is done
  end

  private

    def remove_output_file
      FileUtils.rm(finder_filename) if finder_filename && File.exist?(finder_filename)
    end
end
