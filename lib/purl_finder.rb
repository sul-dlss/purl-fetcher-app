require 'druid-tools'
require 'purl_finder_setup'

class PurlFinder

  include PurlFinderSetup

  # Finds all objects modified since the beginning of time and update database
  # Note: This is not the function to use for processing deletes
  def full_update
    find_and_save
  end

  # Find and then save all public files changed since the specified number of minutes ago (defaults to everything if no time specified
  # Note: This is not the function to use for processing deletes
  #
  # @return [Hash] A hash listing number of docs saved and the total run time {:count => n, :run_time => Seconds_It_Took_To_Run}
  #
  # Example:
  #   results = find_and_save(mins_ago: 100)
  def find_and_save(mins_ago: nil)
    results = {}
    if RunLog.currently_running?
      results[:note] = "Job currently running. No action taken."
      UpdatingLogger.error(results[:note])
      return false
    else
      start_time = Time.zone.now
      output_file = File.join(base_path_finder_log, "#{base_filename_finder_log}_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M-%S-%L')}.txt")
      run_log = RunLog.create(finder_filename: output_file, started: start_time)
      find_files(mins_ago: mins_ago, output_file: output_file)
      save_result = save_purls(output_file: output_file)
      end_time = Time.zone.now
      results[:run_time] = end_time - start_time
      run_log.total_druids = save_result[:count]
      run_log.num_errors = save_result[:error]
      run_log.ended = end_time
      run_log.save
    end
    results.merge(save_result)
  end

  # Find all public files change since the specified number of minutes and store in the database, if no time specified, finds all files
  # returns an integer with the number of files found
  # @param [Hash] mins_ago: The number of minutes to go back and find changes for (defaults to all time if left off)
  # @param [Hash] output_file: The filename location to store the results of the find operation
  # @param [String] The output file where the files were stored
  def find_files(params={})
    mins_ago = params[:mins_ago] || nil
    output_file = params[:output_file] || default_output_file
    search_string = "find #{purl_mount_location} -name public -type f"
    search_string += " -mmin -#{mins_ago.to_i}" if mins_ago
    search_string += "> #{output_file}" # store the results in a tmp file so we don't have to keep everything in memory
    UpdatingLogger.info("Finding public files")
    UpdatingLogger.info(search_string)
    `#{search_string}` # this is the big blocker line - send the find to unix and wait around until its done, at which point we have a file to read in
    output_file
  end

  # Saves purls in the database based on druids found in the output_file, going back to the specified minutes ago
  #  defaults to saving all purls if no time specified
  # returns an integer with the number of files found
  # @param [Hash] output_file: The filename location of found purls to save
  # @return [Hash] A hash with stats on the number of purls saved, success and failure counts
  def save_purls(params={})
    output_file = params[:output_file] || default_output_file
    count = 0
    error = 0
    success = 0
    UpdatingLogger.info("Saving from #{output_file}")
    File.foreach(output_file) do |line| # line will be the full file path, including the druid tree, try and get the druid from this
      druid = get_druid_from_file_path(line)
      if !druid.blank?
        UpdatingLogger.info("updating #{druid}")
        begin
          result = Purl.save_from_public_xml(File.dirname(line)) # pass the directory of the file containing public
        rescue => e
          Honeybadger.notify(e)
          UpdatingLogger.error("An error occurred while trying to save #{druid}.")
        end
        result ? success += 1 : error += 1
        count += 1
      end
    end
    UpdatingLogger.info("Attempted save of #{count} purls; #{success} succeeded, #{error} failed")
    { count: count, success: success, error: error }
  end

  # Finds all objects deleted from purl in the specified number of minutes and updates model to reflect their deletion
  #
  # @return [Hash] A hash providing some stats on the number of items deleted, successful and errored out
  def remove_deleted(params={})
    mins_ago = params[:mins_ago] || nil

    # If we called the below statement with a /* on the end it would not return itself, however it would then throw errors on servers that don't yet have
    # a deleted object and thus don't have a .deletes dir
    search_string = "find #{path_to_deletes_dir}"
    search_string += " -mmin -#{mins_ago.to_i}" if mins_ago

    deleted_objects = `#{search_string}`.split
    deleted_objects -= [path_to_deletes_dir] # remove the deleted objects dir itself

    count = 0
    error = 0
    success = 0
    deleted_objects.each do |fn|
      druid = get_druid_from_delete_path(fn)
      if !druid.blank? && !public_xml_exists?(druid) # double check that the public xml files are actually gone
        UpdatingLogger.info("deleting #{druid}")
        result = Purl.mark_deleted(druid, File.mtime(fn))
        result ? success += 1 : error += 1
        count += 1
      else
        UpdatingLogger.debug { "ignoring #{fn}" }
      end
    end
    { count: count, success: success, error: error }
  end

end
