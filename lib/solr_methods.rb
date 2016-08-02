# Solr related methods for indexing
module SolrMethods

  # Create a object that can be used for RSolr Calls
  #
  # @return [RSolr::Client]
  def solr_connection
    @rsolr ||= RSolr.connect(url: PurlFetcher::Application.config.solr_url, retry_503: 5, retry_after_limit: 15)
  end

  # Establishes a connection to solr and runs a select query and returns the response.  Logs errors and swallows them.
  #
  # @param query [String] A valid query that the RSolr gem will understand how to process via the get method
  # @return [Hash] The solr response.  An empty hash is returned if nothing is found or there is an error.
  def run_solr_query(query)
    response = {}
    begin
      with_retries(max_retries: 5, base_sleep_seconds: 3, max_sleep_seconds: 15, rescue: RSolr::Error) do
        response = solr_connection.get 'select', params: { q: query.to_s, rows: 100_000_000 }
      end
    rescue StandardError => e
      IndexingLogger.error("Unable to select from documents using the query #{query}, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
      return {} # Could return the Exception as well if ever desired, just logs for now
    end
    response
  end

  # Creates a hash that RSolr can use to to create a new solr document for an item
  #
  # @param path [String] The path where the files (mods, contentMetadata, identityMetada) for an object reside
  # @return [Hash] A hash that RSolr can commit to form a new solr document in the form of {:id => 'foo', :title => 'bar', '}, returns {} if a file is not present and a full hash cannot be generated
  #
  def solrize_object(path)
    doc_hash = {}
    purl = PurlParser.new(path)

    if purl.public_xml
      doc_hash[:id] = purl.druid
      doc_hash[indexer_config['title_field'].to_sym] = purl.title
      doc_hash[indexer_config['released_true_field'].to_sym] = purl.releases[:true]
      doc_hash[indexer_config['released_false_field'].to_sym] = purl.releases[:false]
      doc_hash[indexer_config['object_type_field'].to_sym] = purl.object_type
      doc_hash[indexer_config['collection_membership_field'].to_sym] = purl.membership unless purl.membership.empty?
      doc_hash[indexer_config['catkey_field'].to_sym] = purl.catkey unless purl.catkey.empty?
    end
    doc_hash
  end

  # Add a single document to solr
  #
  # @param document [Hash] Rsolr document to add to solr
  # @return [Boolean] True if the documents were added succesfully, false if they were not
  def add_to_solr(document)
    response = {}
    document[indexer_config['change_field'].to_sym] = Time.zone.now.utc.iso8601 # add timestamp to document
    begin
      IndexingLogger.info("Processing item #{document[:id]} (#{document[indexer_config['deleted_field'].to_sym] == 'true' ? 'deleting' : 'adding'})")
      with_retries(max_retries: 5, base_sleep_seconds: 3, max_sleep_seconds: 15, rescue: RSolr::Error) do
        response = solr_connection.add [document]
      end
      result = parse_solr_response(response)
      IndexingLoggererror("Unable to add the document #{document}, solr returned a response of #{response}") unless result
      result
    rescue StandardError => e
      IndexingLogger.error("Unable to add the document #{document}, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
      false
    end
  end

  # Get a list of all documents modified between two times from solr
  #
  # @param first_modified [String] The time the object was first modifed, a string that can be parsed into a valid ISO 8601 formatted time, defaults to the start of Unix time
  # @param last_modified [String] The latest time the object wasmodifed, a string that can be parsed into a valid ISO 8601 formatted time, defaults to now+5 minutes
  # @return [Hash] JSon formatted solr response
  def get_modified_from_solr(first_modified: Time.zone.at(0).iso8601, last_modified: (Time.zone.now + 5.minutes).utc.iso8601)
    times = ModificationTime.get_times(first_modified: first_modified, last_modified: last_modified)
    mod_field = indexer_config['change_field']
    query = "* AND -#{indexer_config['deleted_field']}:'true' AND #{mod_field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]"
    response = run_solr_query(query)
    format_modified_response(response)
  end

  # Get a list of all documents deleted between two times from solr
  #
  # @param first_modified [String] The time the object was first modifed, a string that can be parsed into a valid ISO 8601 formatted time
  # @param last_modified [String] The latest time the object wasmodifed, a string that can be parsed into a valid ISO 8601 formatted time
  # @return [Hash] JSon formatted solr response
  def get_deletes_list_from_solr(first_modified: Time.zone.at(0).iso8601, last_modified: (Time.zone.now + 5.minutes).utc.iso8601)
    times = ModificationTime.get_times(first_modified: first_modified, last_modified: last_modified)
    mod_field = indexer_config['change_field']
    query = "* AND #{indexer_config['deleted_field']}:'true' AND #{mod_field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]"
    solr_resp = run_solr_query(query)

    # TODO: Refactor this and the stuff from format_modified_response into one function
    response = { 'deletes' => [] }

    solr_resp['response']['docs'].each do |doc|
      response['deletes'] << { 'druid' => doc['id'], 'latest_change' => doc['timestamp'] }
    end
    response
  end

  # Takes a solr response and formats it into JSON for the users
  #
  # @param solr_resp [Hash] A Hash generated by an RSolr query
  # @return [Hash] The respnse with unwanted fields removed
  def format_modified_response(solr_resp)
    response = { 'changes' => [] }
    solr_resp['response']['docs'].each do |doc|
      hash = { 'druid' => doc['id'], 'latest_change' => doc['timestamp'] }
      hash['true_targets']  = doc[indexer_config['released_true_field']] unless doc[indexer_config['released_true_field']].nil?
      hash['false_targets'] = doc[indexer_config['released_false_field']] unless doc[indexer_config['released_false_field']].nil?
      response['changes'] << hash
    end
    response
  end

  def delete_document(id)
    response = {}
    begin
      with_retries(max_retries: 5, base_sleep_seconds: 3, max_sleep_seconds: 15, rescue: RSolr::Error) do
        solr_connection.delete_by_id id
      end
      parse_solr_response(response)
    rescue StandardError => e
      IndexingLogger.error("Unable to delete the document with an id of #{id}, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
      return false
    end

    commit_success = commit_to_solr
    IndexingLogger.error("Attempting to commit after deleted the document with an id of #{id} failed.  The specific error returned should be logged above this.") unless commit_success
    commit_success
  end

  # This function determines if the solr action succeeded or not and based on solr's response.  It also determines if solr is showing high response times and
  # sleeps the thread to give solr a chance to recover
  #
  # @param resp [Hash] a hash provided by RSolr, ex: {"responseHeader"=>{"status"=>0, "QTime"=>77}}
  # @return [Boolean] True or false
  def parse_solr_response(resp)
    success = resp['responseHeader']['status'].to_i == 0
    # put this thread to sleep for five seconds if solr looks to be suffered
    sleep(indexer_config['sleep_seconds_if_overloaded'].to_i) if resp['responseHeader']['QTime'].to_i >= indexer_config['sleep_when_response_time_exceeds'].to_i
    success
  end

  # Issue the commit command to solr
  #
  # @return [Boolean] True if the commit was successful, false if it was not
  def commit_to_solr
    response = {}
    begin
      with_retries(max_retries: 5, base_sleep_seconds: 3, max_sleep_seconds: 15, rescue: RSolr::Error) do
        response = solr_connection.commit
      end
    rescue StandardError => e
      IndexingLogger.error("Unable to commit to solr, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
      return false
    end
    parse_solr_response(response)
  end

  # Test The Connect To the Solr Core.  This establishes a connection to the solr cloud and then attempts a basic select against the core the app is configured to use
  #
  # @return [Boolean] true if the select returned a status of 0, false if any other status is returned
  def check_solr_core
    r = solr_connection.get 'select', params: { q: '*:*', rows: 1 } # Just grab one row for the test
    parse_solr_response(r)
  end

end
