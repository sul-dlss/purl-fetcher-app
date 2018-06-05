require 'rails_helper'

describe RunLog, type: :model do
  it "returns the last completed run" do
    expect(described_class.last_completed_run).to eq(nil)
    last_run = described_class.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2)
    expect(described_class.last_completed_run).to eq(last_run)
    described_class.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 1.day, total_druids: 2)
    expect(described_class.last_completed_run).to eq(last_run)
  end

  it "indicates if it is currently running" do
    expect(described_class.currently_running?).to be_falsey # no runs yet
    described_class.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2)
    expect(described_class.currently_running?).to be_falsey # a completed run
    current_run1 = described_class.create(started: Time.zone.now - 1.day, total_druids: 2) # a run that hasn't completed yet
    expect(described_class.currently_running?).to be_truthy
    current_run1.ended = Time.zone.now
    current_run1.save
    expect(described_class.currently_running?).to be_falsey # and now it has completed
  end

  it "returns the time in minutes since the last run started" do
    expect(described_class.minutes_since_last_run_started).to be > 24_492_900 # no runs yet, so go back to beginning of unix time
    described_class.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 30.minutes, total_druids: 2)
    described_class.create(started: Time.zone.now - 4.hours, ended: Time.zone.now - 3.hours, total_druids: 2)
    expect(described_class.minutes_since_last_run_started).to eq(241)
  end

  it "prunes crashed run logs" do
    expect(described_class.count).to eq(0)
    started_at = Time.zone.now - (described_class::CRASHED_PRUNE_TIME_IN_DAYS + 0.1).days
    described_class.create(started: started_at, updated_at: started_at, total_druids: 2) # this started more than the configured maximum runtime ago
    expect(described_class.count).to eq(1)
    described_class.prune_crashed_rows
    expect(described_class.count).to eq(0)
  end

  it "destroy's the finder file when the runlog row is destroyed" do
    purl_finder = PurlFinder.new
    finder_filename = File.join(purl_finder.base_path_finder_log, "#{purl_finder.base_filename_finder_log}_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M-%S-%L')}.txt")
    run1 = described_class.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2, finder_filename: finder_filename)
    FileUtils.touch finder_filename # simulate creation of the finder file
    expect(File.exist?(finder_filename)).to be_truthy
    run1.destroy
    expect(File.exist?(finder_filename)).to be_falsey # the file should be removed by destroying the run log row
  end
end
