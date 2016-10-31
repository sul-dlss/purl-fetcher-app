require 'okcomputer'
require 'uri'

OkComputer.mount_at = 'status' # use /status or /status/all or /status/<name-of-check>
OkComputer.check_in_parallel = true

##
# REQUIRED checks

# Simple echo of the VERSION file
class VersionCheck < OkComputer::AppVersionCheck
  def version
    File.read(Rails.root.join('VERSION')).chomp
  rescue Errno::ENOENT
    raise UnknownRevision
  end
end
OkComputer::Registry.register 'version', VersionCheck.new

# Check to see if process is running
class PidCheck < OkComputer::Check
  def initialize(pid)
    @pid = pid
  end

  def check
    pid = if @pid.respond_to?(:call)
            @pid.call
          else
            @pid
          end
    if pid.present?
      begin
        if Process.kill(0, pid)
          mark_message "process #{pid} is running"
        else
          mark_message "process #{pid} is not responding"
          mark_failure
        end
      rescue Errno::ESRCH, Errno::EPERM
        mark_message "process #{pid} is not running properly"
        mark_failure
      end
    else
      mark_message "no listener process to check?"
      mark_failure
    end
  end
end

# We don't know the pid for the listener until the check method is called
getpid = proc { ListenerLog.current.present? ? ListenerLog.current.process_id : nil }
OkComputer::Registry.register 'feature-listener-process', PidCheck.new(getpid)
