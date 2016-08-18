# Log of purl-fetcher-listener processes that have run or are running
class ListenerLog < ActiveRecord::Base
  ##
  # @return [ListenerLog] the most recent listener that was started
  def self.current
    order('started_at DESC').limit(1).first
  end

  ##
  # @return <Integer|Nil> `nil` if the listener has never run,
  # otherwise time since now that it was last started
  def self.minutes_since_last_started
    ((Time.current - current.started_at) / 60.0).ceil
  rescue
    nil
  end

  ##
  # @return <Integer|Nil> `nil` if the listener has never done any work,
  # otherwise time since now that it was last active
  def self.minutes_since_last_active
    last_log = order('active_at DESC, started_at DESC').limit(1).first
    ((Time.current - last_log.active_at) / 60.0).ceil
  rescue
    nil
  end
end
