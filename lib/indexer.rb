require 'active_support/inflector'
require 'parallel'
require 'logger'
require 'stanford-mods'
require 'retries'
require 'druid-tools'

module Indexer
    include ApplicationHelper
    
    @@indexer_config = DorFetcherService::Application.config.solr_indexing
    @@log = Logger.new('log/indexing.log')
    @@modified_at_or_later = @@indexer_config['default_run_interval_in_minutes'].to_i.minutes.ago #default setting
    
    #Finds all objects modified in the specified number of minutes and indexes them into to solr
    #Note: This is not the function to use for processing deletes
    #
    #@param mins_ago [Fixnum] minutes ago modified, defaults to the interval set in solr_indexing.yml  
    #
    #@return [Hash] A hash listing all the top level branches and the number of solr documents created/updated in each branch and the run time in seconds, ex: {'bb' => 4, 'bc' => 6,...,:runtime => 60}
    #
    #Example:
    #   results = index_all_modified_objects(mins_ago: 5) 
    def index_all_modified_objects(mins_ago: @@indexer_config.default_run_interval_in_minutes.to_i)
      start_time = Time.now
      @@modified_at_or_later = mins_ago.minutes.ago #Set this to a Timestamp that is X minutes this function was called 
      
      #get all the top level branches of the druid tree (currently 400) but remove the .deletes dir
      top_branches_of_tree = Dir.glob(@@indexer_config['purl_document_path']+File::SEPARATOR+"*" ) - [path_to_deletes_dir.to_s]
      
      #Using parallels go down each branch and look for modified items, then index them
      branch_results = Parallel.map(top_branches_of_tree) do |branch|
        index_druid_tree_branch(branch) #This will sweep down the branch and index all files
      end
      end_time = Time.now
      
      #Prep the results for return
      results = {}
      count = 0 
      top_branches_of_tree.each do |branch|
        results[branch] = branch_results[count]
        count += 1
      end
      results[:run_time] = end_time-start_time
      @@log.info("Successfully completed an indexing run of the document_cache.  Runtime was #{end_time-start_time}. Results per top level branch: #{results}")
      return results
      
    end
    
    #Finds all objects deleted from purl in the specified number of minutes and updates solr to reflect their deletion 
    def remove_deleted_objects_from_solr(mins_ago: @@indexer_config.default_run_interval_in_minutes.to_i) 
      minutes_ago = (Time.now-mins_ago.minutes.ago).ceil #use ceil to round up (2.3 becomes 3)
      deleted_objects = `find #{branch} -mmin -#{minutes_ago}`.split
      deleted_objects.each do |d_o|
        #Ensure the object is really deleted, specifically no /purl/document_cache/etc exists for it
      end
      
    end
    
    #Determine if a druid has been deleted and pruned from the document cache or not
    #
    #param druid [String] The druid you are interested in
    #
    #return [Boolean] True or False
    def is_deleted?(druid)
      d = DruidTools::Druid.new(druid, @@indexer_config['purl_document_path'])
      d.base
    end
    
    #Move down one branch of the druid tree (ex: all druids starting with ab) and indexes them into solr
    #
    #param branch [String] The top level branch of the druid tree to scan
    #
    #
    #@return [Fixnum] The number of druids found and updated on this branch
    #Example:
        #   index_druid_tree_branch('/purl/document_cache/bb')
    def index_druid_tree_branch(branch)
      object_paths = get_all_changed_objects_for_branch(branch)
      objects = []
      count = 0
      object_paths.each do |o_path|
        object = solrize_object(o_path)
        objects << object if object != {} #Only add it if we have a valid object, the function ret
        if objects.size == @@indexer_config['items_commit_every']
          add_and_commit_to_solr(objects)
          count += objects.size
          objects = []
        end
      end
    
      add_and_commit_to_solr(objects) if objects.size != 0
      return count += objects.size
    end
    
    #Using the find command with mmin argument, find all files changed since @@modified_at_or_later
    #
    #@param branch [String] The top level branch of the druid tree to scan
    #
    #@return [Array] An array of strings that are the path to the directory the object resides in 
    #
    #Example:
    #   index_druid_tree_branch('/purl/document_cache/bb')
    def get_all_changed_objects_for_branch(branch)
      minutes_ago = (Time.now-@@modified_at_or_later).ceil #use ceil to round up (2.3 becomes 3)
      changed_files = `find #{branch} -mmin -#{minutes_ago}`.split
    
      #We only reindex if something in our changed file list has updated, scan the return list for those and 
      directories_to_reindex = []
      changed_files.each do |file|
        @@indexer_config['files_to_reindex_on'].each do |reindex_trigger|
          directories_to_reindex << file.split(reindex_trigger)[0] if file.include? reindex_trigger
        end
      end
      return directories_to_reindex.uniq #use uniq since mods and version_medata could have changed for the same one 
    end
    
    #Creates a hash that RSolr can use to to create a new solr document for an item
    #
    #@param path [String] The path where the files (mods, contentMetadata, identityMetada) for an object reside
    #
    #@return [Hash] A hash that RSolr can commit to form a new solr document in the form of {:id => 'foo', :title => 'bar', '}, returns {} if a file is not present and a full hash cannot be generated
    #
    def solrize_object(path)
      #Get Information from the mods
      doc_hash = {:foo=>1}
      begin
        doc_hash = read_mods_for_object(path)
      rescue Exception => e
        @@log.error("For #{path} could not load mods.  #{e.message} #{e.backtrace.inspect}")
        return {}
      end
  
      
      #Get the Druid of the object 
      begin
        doc_hash[:id] = get_druid_from_contentMetada(path)
      rescue Exception => e
        @@log.error("For #{path} could not load contentMetadata #{e.message} #{e.backtrace.inspect}")
        return {}
      end
    
      #Get the Release Tags for an object
      begin
        releases = get_release_status(path)
        doc_hash[@@indexer_config['released_true_field'].to_sym] = releases[:true]
        doc_hash[@@indexer_config['released_false_field'].to_sym] = releases[:false]
      rescue Exception => e
        @@log.error("For #{path} no public for #{e.message} #{e.backtrace.inspect}")
        return {}
      end
      return doc_hash

    end
    
    #Given a path to a directory that contains a public xml file, extract the release information
    #
    #param path [String] The path to the directory that will contain the mods file
    #
    #@raises Errno::ENOENT If there is no public file
    #
    #@return [Hash] A hash of all trues and falses in the form of {:true => ['Target1', 'Target2'], :false => ['Target3', 'Target4']}
    #
    #Example:
    #   release_status = get_druid_from_contentMetada('/purl/document_cache/bb')
    def get_release_status(path)
      releases = {:true => [], :false => []}
      x = Nokogiri::XML(File.open(Pathname(path)+'public'))
      nodes = x.xpath('//publicObject/ReleaseData/release')
      nodes.each do |node|
        target = node.attribute('to').text
        status = node.text
        releases[status.downcase.to_sym] << target
      end
      return releases
    end
    
    #Given a path to a directory that contains a mods file, extract the druid for the item from contentMetadata
    #
    #param path [String] The path to the directory that will contain the mods file
    #
    #@raises Errno::ENOENT If there is no mods file
    #
    #@return [String] The druid in the form of druid:pid
    #
    #Example:
    #   druid = get_druid_from_contentMetada('/purl/document_cache/bb')
    def get_druid_from_contentMetada(path)
      x = Nokogiri::XML(File.open(Pathname(path)+'contentMetadata'))
      id = x.xpath('//contentMetadata').attribute('objectId').value
      return "druid:" + id
    end
    
    #Given a path to a directory that contains a mods file, extract info on the object for indexing into solr
    #
    #param path [String] The path to the directory that will contain the mods file
    #
    #@raises Errno::ENOENT If there is no mods file
    #
    #@return [Hash] An hash of mods information in the form of {}:solr_field_name => value}
    #
    #Example:
    #   hash = index_druid_tree_branch('/purl/document_cache/bb')
    def read_mods_for_object(path)
      mods = Stanford::Mods::Record.new
      mods.from_str(IO.read(Pathname(path+File::SEPARATOR+'mods')))
      title = mods.sw_full_title
      return {@@indexer_config['title_field'].to_sym => title }
    end
    
    #Add an array of documents to solr and commit
    #
    #@param documents [Array] An array of hashes that RSolr can add to solr in the form of [{id=>druid:1, title_tsi: "Foo"}]
    #
    #@return [Boolean] True if the documents were added and commited succesfully, false if they were not
    def add_and_commit_to_solr(documents)
      solr = establish_solr_connection
      response = {}
      begin
        with_retries(:max_retries => 5, :base_sleep_seconds => 3, :max_sleep_seconds=> 15, :rescue => RSolr::Error) {
            response = solr.add add_timestamp_to_documents(documents)
        }
        success = parse_solr_response(response)
      rescue Exception => e
        @@log.error("Unable to add the documents #{documents}, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
        return false
      end
      @@log.error("Unable to add the documents #{documents}, solr returned a response of #{response}") if not success
      
      commit_success = commit_to_solr(solr)
      @@log.error("Attempting to commit #{documents} failed.  The specifc error returned should be logged above this.") if not commit_success
      return commit_success
    end
    
    #Adds in the timestamp attribute, using Time.now, to each document about to be committed to Solr
    #
    #@params documents [Array] An array of hashes, with each hash being one solr document
    #
    #@returns [Array] An array of hashes
    def add_timestamp_to_documents(documents)
      documents.each do |d|
        d[@@indexer_config['change_field'].to_sym] = Time.now.utc.iso8601
      end
      return documents 
    end
    
    def delete_document(id)
      solr = establish_solr_connection
      response = {}
      begin
        with_retries(:max_retries => 5, :base_sleep_seconds => 3, :max_sleep_seconds=> 15, :rescue => RSolr::Error) {
            solr.delete_by_id id
        }
        success = parse_solr_response(response)
      rescue Exception => e
        @@log.error("Unable to delete the document with an id of #{id}, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
      end
      
      commit_success = commit_to_solr(solr)
      @@log.error("Attempting to commit after deleted the document with an id of #{id} failed.  The specifc error returned should be logged above this.") if not commit_success
    end
    
    #Create a object that can be used for RSolr Calls
    #
    #@return [RSolr::Client]
    def establish_solr_connection
      return RSolr.connect(:url =>  Solr_URL, :retry_503 => 5, :retry_after_limit => 15)
    end
    
    #This function determines if the solr action succeeded or not and based on solr's response.  It also determines if solr is showing high response times and sleeps the thread to give solr a chance to recover
    #
    #@params resp [Hash] a hash provided by RSolr, ex: {"responseHeader"=>{"status"=>0, "QTime"=>77}} 
    #
    #@return [Boolean] True or false
    def parse_solr_response(resp)
      success = resp['responseHeader']['status'].to_i == 0
      sleep(@@indexer_config['sleep_seconds_if_overloaded'].to_i) if resp['responseHeader']['QTime'].to_i >= @@indexer_config['sleep_when_response_time_exceeds'].to_i #put this thread to sleep for five seconds if solr looks to be suffered
      return success
    end
    
    #Issue the commit command to solr
    #
    #@param solr [Rsolr::Client] an RSolr client
    #
    #@return [Boolean] True if the commit was successful, false if it was not
    def commit_to_solr(solr_client)
      begin
        response = {}
        with_retries(:max_retries => 5, :base_sleep_seconds => 3, :max_sleep_seconds=> 15, :rescue => RSolr::Error) {
            response = solr_client.commit
        }
      rescue Exception => e
        @@log.error("Unable to commit to solr, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
        return false
      end
      return parse_solr_response(response)
    end
    
    #Return the absolute path to the .deletes dir
    #
    #@return [Pathname] The absolute path
    def path_to_deletes_dir 
      return Pathname(@@indexer_config['purl_document_path']+File::SEPARATOR+@@indexer_config['deletes_dir'])
    end
  
    #Get a list of all documents modified between two times from solr
    #
    #@params first_modified [String] The time the object was first modifed, a string that can be parsed into a valid ISO 8601 formatted time
    #@params last_modified [String] The latest time the object wasmodifed, a string that can be parsed into a valid ISO 8601 formatted time
    #
    #@return [Hash] JSon formatted solr response
    def get_modified_from_solr(first_modified:  Time.zone.at(0).iso8601, last_modified: (Time.now + 5.minutes).utc.iso8601)
      app = ApplicationController.new
      times = app.get_times({:first_modified => first_modified, :last_modified=>last_modified})
      mod_field = @@indexer_config['change_field']
      query = "* AND #{mod_field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]"
      solr_client = establish_solr_connection
      begin
         response = {}
         with_retries(:max_retries => 5, :base_sleep_seconds => 3, :max_sleep_seconds=> 15, :rescue => RSolr::Error) {
             response = solr_client.get 'select', :params=>{:q=>"#{query}", :rows => 100000000 }

         }
      rescue Exception => e
        @@log.error("Unable to select from documents using the query #{query}, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
        return {}
      end

      #return response
      return format_modified_response(response)
     
    end
    
    #Takes a solr response and formats it into JSON for the users
    #
    #@params solr_resp [Hash] A Hash generated by an RSolr query
    #
    #@return [Hash] The respnse with unwanted fields removed
    def format_modified_response(solr_resp)
      response = {"documents"=>[]}
      
      solr_resp["response"]["docs"].each do |doc|
        response["documents"] << {"druid"=>doc["id"], "title"=>doc[@@indexer_config['title_field']], "true"=>doc[@@indexer_config['released_true_field']], "false"=>doc[@@indexer_config['released_false_field']], "timestamp"=>doc['timestamp']}
      end
      return response
    end
   
    
end