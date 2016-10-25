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

OkComputer::Registry.register 'purl-document-path',
  OkComputer::DirectoryCheck.new(PurlFetcher::Application.config.app_config['purl_document_path'], false)

OkComputer::Registry.register 'listener-path',
  OkComputer::DirectoryCheck.new(PurlFetcher::Application.config.app_config['listener_path'], true)

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
    if pid.present? && Process.kill(0, pid)
      mark_message "process #{pid} is running"
    else
      mark_message "process #{pid} is not running"
      mark_failure
    end
  end
end

# We don't know the pid for the listener until the check method is called
getpid = proc { ListenerLog.current.present? ? ListenerLog.current.process_id : nil }
OkComputer::Registry.register 'feature-listener-process', PidCheck.new(getpid)
