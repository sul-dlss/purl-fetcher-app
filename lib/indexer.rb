require 'active_support/inflector'
require 'parallel'
require 'logger'
require 'stanford-mods'
require 'retries'
require 'druid-tools'
require 'squash/rails' 
require 'action_controller'

module Indexer
    include ApplicationHelper
    include Squash::Ruby::ControllerMethods
    
    @@indexer_config = DorFetcherService::Application.config.solr_indexing
    @@log = Logger.new("log/indexing.log")
    @@modified_at_or_later = @@indexer_config['default_run_interval_in_minutes'].to_i.minutes.ago #default setting
    @@app = ApplicationController.new

    
    #Finds all objects modified in the specified number of minutes and indexes them into to solr
    #Note: This is not the function to use for processing deletes
    #
    #@param mins_ago [Fixnum] minutes ago modified, defaults to the interval set in solr_indexing.yml  
    #
    #@return [Hash] A hash listing all documents sent to solr and the total run time {:docs => [{Doc1}, {Doc2},...], :run_time => Seconds_It_Took_To_Run}
    #
    #Example:
    #   results = index_all_modified_objects(mins_ago: 5) 
    def index_all_modified_objects(mins_ago: @@indexer_config.default_run_interval_in_minutes.to_i)
      start_time = Time.now
      @@modified_at_or_later = mins_ago.minutes.ago #Set this to a Timestamp that is X minutes this function was called 
      
      #get all the top level branches of the druid tree (currently 400) but remove the .deletes dir
      top_branches_of_tree = Dir.glob(purl_mount_location+File::SEPARATOR+"*" ) - [path_to_deletes_dir.to_s]
      
      #Using parallels go down each branch and look for modified items, then index them
      branch_results = Parallel.map(top_branches_of_tree) do |branch|
        index_druid_tree_branch(branch) #This will sweep down the branch and index all files
      end
      end_time = Time.now
      
      #Prep the results for return
      results = {}
      results[:docs] = []
      count = 0 
      top_branches_of_tree.each do |branch|
        results[:docs] += branch_results[count]
        count += 1
      end
      results[:run_time] = end_time-start_time
      @@log.info("Successfully completed an indexing run of the document_cache.  Runtime was #{end_time-start_time}. The documents changed were: #{results}")
      return results
      
    end
    
    #Finds all objects deleted from purl in the specified number of minutes and updates solr to reflect their deletion 
    #
    #
    #@return [Hash] A hash stating if the deletion was successful or not and an array of the docs {:success=> true/false, :docs => [{doc1},{doc2},...]}
    def remove_deleted_objects_from_solr(mins_ago: @@indexer_config.default_run_interval_in_minutes.to_i) 
      #minutes_ago = ((Time.now-mins_ago.minutes.ago)/60.0).ceil #use ceil to round up (2.3 becomes 3)
      query_path = Pathname(path_to_deletes_dir.to_s)
      deleted_objects = `find #{query_path} -mmin -#{mins_ago}`.split #If we called this with a /* on the end it would not return itself, however it would then throw errors on servers that don't yet have a deleted object and thus don't have a .deletes dir
      deleted_objects = deleted_objects-[query_path.to_s] # remove the deleted objects dir itself
      
      docs = []
      result = true #set this to true by default because if we get an empty list of documents, then it worked
      deleted_objects.each do |d_o|
        #Check to make sure that the object is really deleted 
        druid = d_o.split(query_path.to_s+File::SEPARATOR)[1]
        if druid != nil && is_deleted?(druid) 
          #delete_document(d_o) #delete the current document out of solr
          docs << {:id => ('druid:'+druid), @@indexer_config['deleted_field'].to_sym => 'true'}
        end
        result = add_and_commit_to_solr(docs) if docs.size != 0 #load in the new documents with the market to show they are deleted
      end
      return {:success => result, :docs => docs}
      
    end
    
    #Determine if a druid has been deleted and pruned from the document cache or not
    #
    #param druid [String] The druid you are interested in
    #
    #return [Boolean] True or False
    def is_deleted?(druid)
      d = DruidTools::PurlDruid.new(druid, purl_mount_location)
      dir_name = Pathname(d.path) #This will include the full druid on the end of the path, we don't want that for purl
      return !File.directory?(dir_name) #if the directory does not exist (so File returns false) then it is really deleted
    end
    
    #Move down one branch of the druid tree (ex: all druids starting with ab) and indexes them into solr
    #
    #param branch [String] The top level branch of the druid tree to scan
    #
    #
    #@return [Array] A list of all objects added to solr
    #Example:
        #   index_druid_tree_branch('/purl/document_cache/bb')
    def index_druid_tree_branch(branch)
      object_paths = get_all_changed_objects_for_branch(branch)
      all_objects = []
      objects = []
      object_paths.each do |o_path|
        object = solrize_object(o_path)
        objects << object if object != {} #Only add it if we have a valid object, the function ret
        if objects.size == @@indexer_config['items_commit_every']
          add_and_commit_to_solr(objects)
          all_objects += objects
          objects = []
        end
      end
    
      add_and_commit_to_solr(objects) if objects.size != 0
      return all_objects += objects
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
      minutes_ago = ((Time.now-@@modified_at_or_later)/60.0).ceil #use ceil to round up (2.3 becomes 3)
      changed_files = `find #{branch} -mmin -#{minutes_ago}`.split
    
      #We only reindex if something in our changed file list has updated, scan the return list for those and 
      directories_to_reindex = []
      changed_files.each do |file|
        @@indexer_config['files_to_reindex_on'].each do |reindex_trigger|
          directories_to_reindex << file.split(reindex_trigger)[0] if file.include? reindex_trigger
        end
      end
      return directories_to_reindex.uniq #use uniq since mods and version_medata could have changed for the same one and caused it to appear twice on this list
    end
    
    #Creates a hash that RSolr can use to to create a new solr document for an item
    #
    #@param path [String] The path where the files (mods, contentMetadata, identityMetada) for an object reside
    #
    #@return [Hash] A hash that RSolr can commit to form a new solr document in the form of {:id => 'foo', :title => 'bar', '}, returns {} if a file is not present and a full hash cannot be generated
    #
    def solrize_object(path)
      #TODO: Refactor me just to pop open the files in one block and then pull the stuff out.  So many begin/rescues...      
      
      #Get Information from the mods
      doc_hash = {}
      begin
        doc_hash = read_mods_for_object(path)
      rescue Exception => e
        #@@app.alert_squash e
        @@log.error("For #{path} could not load mods.  #{e.message} #{e.backtrace.inspect}")
        return {}
      end
  
      
      #Get the Druid of the object 
      begin
        doc_hash[:id] = get_druid_from_publicMetadata(path)
      rescue Exception => e
        #@@app.alert_squash e
        @@log.error("For #{path} could not load contentMetadata #{e.message} #{e.backtrace.inspect}")
        return {}
      end
    
      #Get the Release Tags for an object
      begin
        releases = get_release_status(path)
        doc_hash[@@indexer_config['released_true_field'].to_sym] = releases[:true]
        doc_hash[@@indexer_config['released_false_field'].to_sym] = releases[:false]
      rescue Exception => e
        #@@app.alert_squash e
        @@log.error("For #{path} no public xml, Error: #{e.message} #{e.backtrace.inspect}")
        return {}
      end
      
      #Below these we log an error, but don't fail as we can still update the item and flag the indexer, we just don't have all the data we want
      
      #Get the ObjectType for an object
      begin
        doc_hash[Type_Field.to_sym] = get_objectType_from_identityMetadata(path)
      rescue Exception => e
        #@@app.alert_squash e
        @@log.error("For #{path} no identityMetada containing an object type.  Error: #{e.message} #{e.backtrace.inspect}")
      end
      
      #Get membership of sets and collections for an object
      begin
        membership = get_membership_from_publicxml(path)
        doc_hash[Solr_terms["collection_field"].to_sym] = membership if membership.size > 0 #only add this if we have a membership
      rescue Exception => e
        #@@app.alert_squash e
        @@log.error("For #{path} no public xml or an error occurred while getting membership from the public xml.  Error: #{e.message} #{e.backtrace.inspect}")
      end
      
      #Get the catkey of an object
      begin
        catkey = get_catkey_from_identityMetadata(path)
        doc_hash[@@indexer_config['catkey_field'].to_sym] = catkey if catkey.size > 0 #only add this if we have a catkey
      rescue Exception => e
        #@@app.alert_squash e
        @@log.error("For #{path} no identityMetadata or an error occurred while getting the catkey.  Error: #{e.message} #{e.backtrace.inspect}")
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
      nodes = x.xpath('//publicObject/releaseData/release')
      nodes.each do |node|
        target = node.attribute('to').text
        status = node.text
        releases[status.downcase.to_sym] << target
      end
      return releases
    end
    
    #Given a path to a directory that contains an identityMetada file, extract the druid for the item from identityMetadata.  This is currently not used because as it turns out, not all identityMetadatas have this node in them.  Rather use get_druid_from_contentMetadata
    #
    #param path [String] The path to the directory that will contain the identityMetadata file
    #
    #@raises Errno::ENOENT If there is no identityMetadata file
    #
    #@return [String] The druid in the form of druid:pid
    #
    #Example:
    #   druid = get_druid_from_identityMetadata('/purl/document_cache/bb')
    def get_druid_from_identityMetadata(path)
      x = Nokogiri::XML(File.open(Pathname(path)+'identityMetadata'))
      return x.xpath("//identityMetadata/objectId")[0].text
    end
    
    #Given a path to a directory that contains a public metadata file, extract the druid for the item from identityMetadata.  
    #
    #param path [String] The path to the directory that will contain the public metadata file
    #
    #@raises Errno::ENOENT If there is no public metadata file
    #
    #@return [String] The druid in the form of druid:pid
    #
    #Example:
    #   druid = get_druid_from_publicMetadata('/purl/document_cache/bb')
    def get_druid_from_publicMetadata(path)
      x = Nokogiri::XML(File.open(Pathname(path)+'public'))
      return x.xpath('//publicObject')[0].attr('id')
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
        #@@app.alert_squash e
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
        #@@app.alert_squash e
        @@log.error("Unable to delete the document with an id of #{id}, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
        return false
      end
      
      commit_success = commit_to_solr(solr)
      @@log.error("Attempting to commit after deleted the document with an id of #{id} failed.  The specifc error returned should be logged above this.") if not commit_success
      return commit_success
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
        #@@app.alert_squash e
        @@log.error("Unable to commit to solr, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
        return false
      end
      return parse_solr_response(response)
    end
    
    #Return the absolute path to the .deletes dir
    #
    #@return [Pathname] The absolute path
    def path_to_deletes_dir 
      return Pathname(purl_mount_location+File::SEPARATOR+@@indexer_config['deletes_dir'])
    end
  
    #Get a list of all documents modified between two times from solr
    #
    #@params first_modified [String] The time the object was first modifed, a string that can be parsed into a valid ISO 8601 formatted time
    #@params last_modified [String] The latest time the object wasmodifed, a string that can be parsed into a valid ISO 8601 formatted time
    #
    #@return [Hash] JSon formatted solr response
    def get_modified_from_solr(first_modified:  Time.zone.at(0).iso8601, last_modified: (Time.now + 5.minutes).utc.iso8601)
      times = @@app.get_times({:first_modified => first_modified, :last_modified=>last_modified})
      mod_field = @@indexer_config['change_field']
      query = "* AND -#{@@indexer_config['deleted_field']}:'true' AND #{mod_field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]"
      
      response = run_solr_query(query)
      return format_modified_response(response)
     
    end
    
    
    
    #Get a list of all documents deleted between two times from solr
    #
    #@params first_modified [String] The time the object was first modifed, a string that can be parsed into a valid ISO 8601 formatted time
    #@params last_modified [String] The latest time the object wasmodifed, a string that can be parsed into a valid ISO 8601 formatted time
    #
    #@return [Hash] JSon formatted solr response
    def get_deletes_list_from_solr(first_modified:  Time.zone.at(0).iso8601, last_modified: (Time.now + 5.minutes).utc.iso8601)
      times = @@app.get_times({:first_modified => first_modified, :last_modified=>last_modified})
      mod_field = @@indexer_config['change_field']
      query = "* AND #{@@indexer_config['deleted_field']}:'true' AND #{mod_field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]"
      solr_resp = run_solr_query(query)
      
      #TODO: Refactor this and the stuff from format_modified_response into one function
      response = {"deletes"=>[]}
   
      
      solr_resp["response"]["docs"].each do |doc|
        hash = {"druid"=>doc["id"], "latest_change"=>doc['timestamp']}
        response["deletes"] << hash
      end
      return response
      
    end
    
    #Establishes a connection to solr and runs a select query and returns the response.  Logs errors and swallows them.
    #
    #@params query [String] A valid query that the RSolr gem will understand how to process via the get method
    #
    #@return [Hash] The solr response.  An empty hash is returned if nothing is found or there is an error.
    def run_solr_query(query)
      solr_client = establish_solr_connection
      response = {}
      begin
         with_retries(:max_retries => 5, :base_sleep_seconds => 3, :max_sleep_seconds=> 15, :rescue => RSolr::Error) {
             response = solr_client.get 'select', :params=>{:q=>"#{query}", :rows => 100000000 }

         }
      rescue Exception => e
        @@log.error("Unable to select from documents using the query #{query}, solr returned a response of #{response} and an exception of #{e.message} occurred, #{e.backtrace.inspect} ")
        return {} #Could return the Exception as well if ever desired, just logs for now
      end
      return response
    end
    
    #Takes a solr response and formats it into JSON for the users
    #
    #@params solr_resp [Hash] A Hash generated by an RSolr query
    #
    #@return [Hash] The respnse with unwanted fields removed
    def format_modified_response(solr_resp)
      response = {"changes"=>[]}
   
      
      solr_resp["response"]["docs"].each do |doc|
        hash = {"druid"=>doc["id"], "latest_change"=>doc['timestamp']}
        hash["true_targets"] = doc[@@indexer_config['released_true_field']] if doc[@@indexer_config['released_true_field']] != nil
        hash["false_targets"] =doc[@@indexer_config['released_false_field']] if doc[@@indexer_config['released_false_field']] != nil
        response["changes"] << hash
      end
      return response
    end
    
    #Accessor to get the purl document cache path
    #
    #@return [String] The path
    def purl_mount_location
      return @@indexer_config['purl_document_path']
    end
    
    
    #Given a path to a directory that contains a public xml file, extract the collections and sets for the item from identityMetadata
    #
    #param path [String] The path to the directory that will contain the identityMetadata file
    #
    #@raises Errno::ENOENT If there is no identity Metadata File
    #
    #@return [Array] The object types
    #
    #Example:
    #   get_objectType_from_identityMetadata('/purl/document_cache/bb')
    def get_objectType_from_identityMetadata(path)
      x = Nokogiri::XML(File.open(Pathname(path)+'identityMetadata'))
      types = []
      x.xpath("//identityMetadata/objectType").each do |n|
        types << n.text
      end
      return types
    end
    
    #Given a path to a directory that contains a public xml file, extract collections and sets the item is a member of
    #
    #param path [String] The path to the directory that will contain the public xml
    #
    #@raises Errno::ENOENT If there is no public xml file
    #
    #@return [Array] The collections and sets the item is a member of
    #
    #Example:
    #   get_membership_from_publicxml('/purl/document_cache/bb')
    def get_membership_from_publicxml(path)
      x = Nokogiri::XML(File.open(Pathname(path)+'public'))
      x.remove_namespaces!
      types = []
      x.xpath("//RDF/Description/isMemberOfCollection").each do |n|
        types << n.attribute('resource').text.split('/')[1]
      end
      return types
    end
    
    #Given a path to a directory that contains an indentityMetadata xml file, extract collections and sets the item is a member of
    #
    #param path [String] The path to the directory that will contain the identity Metadata File
    #
    #@raises Errno::ENOENT If there is no identity Metadata File
    #
    #@return [String] The cat key, an empty string is returned if there is no catkey
    #
    #Example:
    #   get_catkey_from_identityMetadata('/purl/document_cache/bb')
    def get_catkey_from_identityMetadata(path)
      x = Nokogiri::XML(File.open(Pathname(path)+'identityMetadata'))
     return x.xpath("//otherId[@name='catkey']").text
    end
    
    #Method to return the indexing log to anyone interested (ex rspec tests)
    #
    #@returns [Logger] The log
    def log_object
      return @@log
    end
    
    #Method to return the application controller to anyone interested (ex rspec tests)
    #
    #@returns [ApplicatonController] application controller
    def app_controller
      return @@app
    end
    
    #Test The Connect To the Solr Core.  This establishes a connection to the solr cloud and then attempts a basic select against the core the app is configured to use
    #
    #@returns [Boolean] True/False, true if the select returned a status of 0, false if any other status is returned
    def check_solr_core
      solr_client = establish_solr_connection
      r = solr_client.get 'select', :params => {:q => '*:*', :rows=>1} #Just grab one row for the test
      return parse_solr_response(r)
    end
    
    
   
   
    
end