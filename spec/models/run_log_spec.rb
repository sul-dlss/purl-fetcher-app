require 'spec_helper'

module Editstore
  describe RunLog, type: :model do
    it "returns the last completed run" do
      expect(RunLog.last_completed_run).to eq(nil)
      last_run = RunLog.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2)
      expect(RunLog.last_completed_run).to eq(last_run)
      RunLog.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 1.day, total_druids: 2)
      expect(RunLog.last_completed_run).to eq(last_run)
    end

    it "indicates if it is currently running" do
      expect(RunLog.currently_running?).to be_falsey
      RunLog.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2)
      expect(RunLog.currently_running?).to be_falsey
      current_run1 = RunLog.create(started: Time.zone.now - 1.day, total_druids: 2)
      expect(RunLog.currently_running?).to be_truthy
      current_run1.ended = Time.zone.now
      current_run1.save
      expect(RunLog.currently_running?).to be_falsey
    end

    it "returns the last run time in minutes" do
      RunLog.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 30.minutes, total_druids: 2)
      RunLog.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.hour, total_druids: 2)
      expect(RunLog.last_run_time_in_minutes).to eq(61)
    end

    it "returns the time in minutes since the last run completed" do
      RunLog.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 30.minutes, total_druids: 2)
      RunLog.create(started: Time.zone.now - 4.hours, ended: Time.zone.now - 3.hours, total_druids: 2)
      expect(RunLog.minutes_since_last_run_ended).to eq(181)
    end

    it "returns the time in minutes since the last run started" do
      RunLog.create(started: Time.zone.now - 2.months, ended: Time.zone.now - 2.months + 30.minutes, total_druids: 2)
      RunLog.create(started: Time.zone.now - 4.hours, ended: Time.zone.now - 3.hours, total_druids: 2)
      expect(RunLog.minutes_since_last_run_started).to eq(241)
    end

    it "prunes older run logs" do
      run1 = RunLog.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2)
      run1.updated_at = Time.zone.now - 2.months
      run1.save
      run2 = RunLog.create(started: Time.zone.now - 1.day, ended: Time.zone.now - 1.day + 1.hour, total_druids: 2)
      run3 = RunLog.create(started: Time.zone.now - 2.days, ended: Time.zone.now - 1.day + 2.hours, total_druids: 0)
      run3.updated_at = Time.zone.now - 2.days
      run3.save
      current_run1 = RunLog.create(started: Time.zone.now - 1.day, total_druids: 2)
      expect(RunLog.count).to eq(4)
      RunLog.prune
      expect(RunLog.count).to eq(3)
      expect(RunLog.all).to eq([run1, run2, current_run1])
    end

    it "prunes all completed run logs" do
      run1 = RunLog.create(started: Time.zone.now - 1.month, ended: Time.zone.now - 1.month + 1.day, total_druids: 2)
      run1.updated_at = Time.zone.now - 2.months
      run1.save
      RunLog.create(started: Time.zone.now - 1.day, ended: Time.zone.now - 1.day + 1.hour, total_druids: 2)
      current_run1 = RunLog.create(started: Time.zone.now - 1.day, total_druids: 2)
      expect(RunLog.count).to eq(3)
      RunLog.prune_all
      expect(RunLog.count).to eq(1)
      expect(RunLog.all).to eq([current_run1])
    end
  end
end
