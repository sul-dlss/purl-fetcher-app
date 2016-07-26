require 'active_support/inflector'
require 'logger'
require 'stanford-mods'
require 'retries'
require 'druid-tools'
require 'action_controller'
require 'solr_methods'
require 'parser_methods'
require 'indexer_setup'

class Indexer

  include SolrMethods
  include ParserMethods
  include IndexerSetup

  # Finds all objects modified since the beginning of time.
  # Note: This is not the function to use for processing deletes
  def full_reindex
    find_and_index
  end

  # Finds all objects modified since the last time indexing was run
  # Note: This is not the function to use for processing deletes
  def index_since_last_run
    modified_at_or_later = RunLog.minutes_since_last_run_started
    find_and_index(mins_ago: modified_at_or_later)
  end

  # find and then index all public files changed since the specified number of minutes ago
  #  defaults to all if no time specified
  # Note: This is not the function to use for processing deletes
  #
  # @return [Hash] A hash listing all documents sent to solr and the total run time {:docs => [{Doc1}, {Doc2},...], :run_time => Seconds_It_Took_To_Run}
  #
  # Example:
  #   results = find_and_index(100)
  def find_and_index(mins_ago: nil)
    start_time = Time.zone.now
    results = {}
    if RunLog.currently_running?
      log.info("Job currently running. No action taken.")
    else
      output_file=File.join(base_path_finder_log,"#{base_filename_finder_log}_#{Time.zone.now.strftime('%Y-%m-%d_%H-%M-%S')}.txt")
      run_log=RunLog.create(finder_filename: output_file, started: start_time)
      find_files(mins_ago: mins_ago, output_file: output_file)
      index_purls(mins_ago: mins_ago)
    end
    end_time = Time.zone.now
    results[:run_time] = end_time - start_time
    run_log.ended = end_time
    run_log.save
    results
  end

  # find all public files change since the specified number of minutes and store in the database
  #  if no time specified, finds all files
  # returns an integer with the number of files found
  # @param [Integer] Set as a hash key of mins_ago: The number of minutes to go back and find changes for (defaults to all time if left off)
  # @param [Integer] Set as a hash key of output_file: The filename location to store the results of the find operation
  def find_files(params={})
    mins_ago = params[:mins_ago] || nil
    output_file = params[:output_file] || File.join(base_path_finder_log,"output.txt")
    if mins_ago
      search_string = "find #{purl_mount_location} -name public -type f -mmin -#{mins_ago}"
    else
      search_string = "locate \"#{purl_mount_location}/*public*\""
    end
    search_string += "> #{output_file}" # store the results in a tmp file so we don't have to keep everything in memory
    log.info(search_string)
    search_result=`#{search_string}`  # this is the big blocker line - send the find to unix and wait around until its done, at which point we have a file to read in
    return true
  end

  # indexes purls based on druids found in the database, going back to the specified minutes ago
  #  defaults to indexing all purls if no time specified
  # returns an integer with the number of files found
  # @param [Integer] Set as a hash key of mins_ago: The number of minutes to go back and find changes for (defaults to all time if left off)
  # @return [Integer] Number of purls indexed
  def index_purls(mins_ago: nil)
    # TODO: Iterate over purls in database and index each one
    count=0

    count
  end

  # Finds all objects deleted from purl in the specified number of minutes and updates solr to reflect their deletion
  #
  # @return [Hash] A hash stating if the deletion was successful or not and an array of the docs {:success=> true/false, :docs => [{doc1},{doc2},...]}
  def remove_deleted_objects_from_solr(mins_ago: indexer_config.default_run_interval_in_minutes.to_i)
    # minutes_ago = ((Time.zone.now-mins_ago.minutes.ago)/60.0).ceil #use ceil to round up (2.3 becomes 3)
    query_path = Pathname(path_to_deletes_dir.to_s)
    # If we called the below statement with a /* on the end it would not return itself, however it would then throw errors on servers that don't yet have
    # a deleted object and thus don't have a .deletes dir
    deleted_objects = `find #{query_path} -mmin -#{mins_ago}`.split
    deleted_objects -= [query_path.to_s] # remove the deleted objects dir itself

    docs = []
    result = true # set this to true by default because if we get an empty list of documents, then it worked
    deleted_objects.each do |d_o|
      # Check to make sure that the object is really deleted
      druid = d_o.split(query_path.to_s + File::SEPARATOR)[1]
      if !druid.nil? && deleted?(druid)
        # delete_document(d_o) #delete the current document out of solr
        docs << { :id => ('druid:' + druid), indexer_config['deleted_field'].to_sym => 'true' }
      end
      result = add_and_commit_to_solr(docs) unless docs.empty? # load in the new documents with the market to show they are deleted
    end
    { success: result, docs: docs }
  end

end
