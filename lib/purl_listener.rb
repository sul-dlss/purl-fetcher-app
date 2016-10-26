require 'benchmark'
require 'fileutils'
require 'listen'

##
# PurlListener supports incremental PURL updates via a "dropbox" folder
# on the PURL filesystem. The implementation assumes that the PURL filesystem
# is mounted via NFS and is a read-write mount.
#
# This is the basic algorithm:
#
# watches "dropbox" directory for filesystem events,
# then on event:
#     - logs that the listener process is active
#     - rename `aa111bb2222` to `aa111bb2222.lock`
#     - save to `Purl` model, and logs (to file and Honeybadger) any exceptions (then continues)
#     - delete `aa111bb2222.lock`
#
# when listener boots:
#     - it checks to see when it was last active
#     - then runs a `find:all[mins_ago]` task
#
class PurlListener

  attr_reader :event_handler, :logger, :path, :pid_file

  ##
  # @param [Pathname] `path` -- the single "dropbox" directory
  # @param [Pathname] `pid_file` -- the location of the pid file
  # @param [Logger] `logger` -- place to log info/warn/errors
  # @raise [ArgumentError] -- requires path to be a directory
  def initialize(path = Pathname(Settings.LISTENER_PATH),
                 pid_file = Pathname(Settings.LISTENER_PID_FILE),
                 logger = UpdatingLogger)
    raise ArgumentError, "Missing #{path}" unless path.directory?
    @pid_file = pid_file
    @pid = nil
    @path = path
    @logger = logger
    @event_handler = proc do |modified, added, removed|
      modified.map { |fn| process_event(Pathname(fn)) }
      added.map { |fn| process_event(Pathname(fn)) }
      removed.map { |fn| logger.debug "Ignoring removed event for #{fn}" }
    end
  end

  ##
  # Starts the listener process as a daemon
  def start
    logger.info("Starting listener")
    run_delta
    listen_for_changes # does not return until an Exception/Signal happens
  ensure
    remove_pid_file
  end

  ##
  # Stops the listener process and cleans up pid file
  def stop
    logger.info("Stopping listener")
    if running?
      begin
        Process.kill('TERM', pid)
      rescue Errno::ESRCH
        return # process doesn't exist
      end
    end
  ensure
    remove_pid_file
  end

  ##
  # @return [Integer|Nil] reads `pid` from the `pid_file` if not set
  def pid
    @pid ||= begin
      pid_file.read.to_i
    rescue Errno::ENOENT
      nil
    end
  end

  ##
  # @return [Boolean] is the listener process already running?
  def running?
    pid ? Process.kill(0, pid) : false
  rescue Errno::ESRCH
    false
  end

  private

    ##
    # runs a `find:all` process to catch up since the last time the
    # listener process was active.
    def run_delta
      mins_ago = ListenerLog.minutes_since_last_active
      if mins_ago.nil?
        logger.warn('WARNING: Must run "rake find:all" as listener has never done any work')
      else
        run_find_all(mins_ago)
      end
    end

    ##
    # Uses the `listen` gem to monitor the "dropbox" folder for changes.
    # Daemonizes the process and child does not return until SignalException.
    # @return does not return -- blocks on a `sleep`
    def listen_for_changes
      logger.info("Listening to #{path}")
      listener = Listen.to(path,
                           force_polling: true, # because on NFS mount
                           ignore: [/\.lock$/],
                           latency: 60,         # wait between polling
                           wait_for_delay: 5,   # see #157: slow down delta between change notice and action due to NFS
                           &event_handler)
      Process.daemon(true)
      @pid = $PROCESS_ID
      write_pid_file
      Process.setproctitle('[purl-fetcher-listener]')
      ListenerLog.create(process_id: pid, started_at: Time.current)
      listener.start
      sleep # wait forever -- work is done by `event_handler`
    end

    ##
    # processes the listener file event -- assumes only adds and changes
    # @param [Pathname] file that was added or changed
    def process_event(fn)
      mark_active
      druid = fn.basename.to_s
      if DruidTools::Druid.valid?(druid)
        elapsed_time = Benchmark.realtime do
          begin
            process_druid_file(fn, druid)
          rescue => e
            logger.error("Cannot process #{druid}: #{e.message}")
            Honeybadger.notify(e) # backtrace is available there
            return
          end
        end
        logger.info("Processed #{druid} in #{elapsed_time} seconds")
      else
        logger.warn("Ignoring miscellaneous file #{fn}")
      end
    end

    ##
    # actually do the work to save the PURL based on the `public` file
    # uses `.lock` files in case the same druid is published during the
    # time we run the save. On exception, we leave the .lock file as-is.
    # @param [Pathname] `fn` the event file
    # @param [String] `druid`
    def process_druid_file(fn, druid)
      lockfile = fn.sub_ext('.lock')
      fn.rename(lockfile.to_s) # renaming the file allows a republish during our work
      Purl.save_from_public_xml(purl_path(druid))
      lockfile.delete
    end

    def remove_pid_file
      pid_file.delete
    rescue Errno::ENOENT
      logger.info("no PID file")
    end

    def write_pid_file
      pid_file.write(@pid.to_s)
    end

    def run_find_all(mins_ago)
      system("rake find:all[#{mins_ago}] </dev/null >/dev/null 2>/dev/null &") # daemonize
    end

    def purl_path(druid)
      PurlFinder.new.purl_path(druid)
    end

    def mark_active
      log = ListenerLog.current
      log.active_at = Time.current
      log.save!
    end
end
