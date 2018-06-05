class RunLog < ApplicationRecord

  CRASHED_PRUNE_TIME_IN_DAYS = 0.5 # after this many days, any job which has not yet ended is assumed to have crashed and is removed

  before_destroy :remove_output_file

  # check to see if there is a job currently running according to the logs...this is a job with no end time yet
  def self.currently_running?
    prune_crashed_rows
    where(ended: nil).order('ended DESC').size == 1
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

  private

    def remove_output_file
      FileUtils.rm(finder_filename) if finder_filename && File.exist?(finder_filename)
    end
end
