class RunLog < ActiveRecord::Base

  # check to see if there is a job currently running according to the logs...this is a job with no end time yet
  def self.currently_running?
    prune_crashed_rows
    self.where(ended: nil).order('ended DESC').size == 1
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
    ((Time.zone.now - last_row.ended) / 60.0).ceil if last_completed_run
  end

  # how many minutes ago the last run started, useful for determining how far back to start for next run, rounded up
  def self.minutes_since_last_run_started
    prune_crashed_rows
    last_row = last_completed_run
    ((Time.zone.now - last_row.started) / 60.0).ceil if last_completed_run
  end


  # the last completed run, returned as a model object
  def self.last_completed_run
    self.order('ended DESC').find_by('ended IS NOT NULL')
  end

  # remove all rows with no end time that were started more than 2 days ago (i.e. the job was started and must have died without completing the entry)
  def self.prune_crashed_rows
    self.where('updated_at < ?', 2.days.ago).where('ended IS NULL').each(&:destroy)
  end

  # prune the logs by removing older completed jobs
  def self.prune
    prune_crashed_rows
    self.where('updated_at < ?', 6.months.ago).each(&:destroy) # anything older than 6 months
    self.where(total_druids: 0).where('updated_at < ?', 1.day.ago).each(&:destroy) # anything older than 1 day with no activity
  end

  # remove all completed logs
  def self.prune_all
    self.where('ended IS NOT NULL').each(&:destroy) # anything that is done
  end
end
