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

  it "returns the last run time in minutes if one exists" do
    expect(described_class.last_run_time_in_minutes).to eq(nil) # no runs yet
    described_class.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 30.minutes, total_druids: 2)
    described_class.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.hour, total_druids: 2)
    expect(described_class.last_run_time_in_minutes).to eq(61)
  end

  it "returns the time in minutes since the last run completed" do
    expect(described_class.minutes_since_last_run_ended).to be > 24_492_900 # no runs yet, so go back to beginning of unix time
    described_class.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 30.minutes, total_druids: 2)
    described_class.create(started: Time.zone.now - 4.hours, ended: Time.zone.now - 3.hours, total_druids: 2)
    expect(described_class.minutes_since_last_run_ended).to eq(181)
  end

  it "returns the time in minutes since the last run started" do
    expect(described_class.minutes_since_last_run_started).to be > 24_492_900 # no runs yet, so go back to beginning of unix time
    described_class.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 30.minutes, total_druids: 2)
    described_class.create(started: Time.zone.now - 4.hours, ended: Time.zone.now - 3.hours, total_druids: 2)
    expect(described_class.minutes_since_last_run_started).to eq(241)
  end

  it "prunes older run logs" do
    run1 = described_class.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2)
    run1.updated_at = Time.zone.now - 2.months
    run1.save
    run2 = described_class.create(started: Time.zone.now - 1.day, ended: Time.zone.now - 1.day + 1.hour, total_druids: 2)
    run3 = described_class.create(started: Time.zone.now - 2.days, ended: Time.zone.now - 1.day + 2.hours, total_druids: 0)
    run3.updated_at = Time.zone.now - 2.days
    run3.save
    current_run1 = described_class.create(started: Time.zone.now - 1.day, total_druids: 2)
    expect(described_class.count).to eq(4)
    described_class.prune
    expect(described_class.count).to eq(3)
    expect(described_class.all).to eq([run1, run2, current_run1])
  end

  it "prunes all completed run logs" do
    run1 = described_class.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2)
    run1.updated_at = Time.zone.now - 2.months
    run1.save
    described_class.create(started: Time.zone.now - 1.day, ended: Time.zone.now - 1.day + 1.hour, total_druids: 2)
    current_run1 = described_class.create(started: Time.zone.now - 1.day, total_druids: 2)
    expect(described_class.count).to eq(3)
    described_class.prune_all
    expect(described_class.count).to eq(1)
    expect(described_class.all).to eq([current_run1])
  end
end
