require 'rails_helper'

describe("Indexer lib")  do
  include ApplicationHelper
  
  before :all do
    @indexer = IndexerTester.new
    @testing_druid = 'bb050dj7711'
    @testing_doc_cache = purl_fixture_path
    #@testing_doc_cache = Rails.root.to_s + (File::SEPARATOR+'spec'+File::SEPARATOR+'purl-fixtures-testing'+File::SEPARATOR+'document_cache')
    @sample_doc_path =  DruidTools::PurlDruid.new(@testing_druid, @testing_doc_cache).path
    @sample_doc_path_files_missing = DruidTools::PurlDruid.new('bb050dj0000', @testing_doc_cache).path
    @ct961sj2730_path =  @druid_object = DruidTools::PurlDruid.new('ct961sj2730', @testing_doc_cache).path #this one has a catkey and is a top level collection
   
  end
  
  describe("testing connectivity to the solr core") do
    before :all do
      @s_c = @indexer.establish_solr_connection
    end
    
    it "returns true when the solr core responds to a select" do
      allow(@indexer).to receive(:establish_solr_connection).and_return(@s_c)
      allow(@s_c).to receive(:get).and_return({'responseHeader'=>{'status'=>0}})
      expect(@indexer.check_solr_core).to be_truthy
    end
    
    it "returns false when the solr core does not respond to a select" do
      allow(@indexer).to receive(:establish_solr_connection).and_return(@s_c)
      allow(@s_c).to receive(:get).and_return({'responseHeader'=>{'status'=>1}})
      expect(@indexer.check_solr_core).to be_falsey
    end
  end
  
  describe('incremental commits to solr') do
    before :all do
      @branch = '/test/branch'
      @commit_every_n = DorFetcherService::Application.config.solr_indexing['items_commit_every'].to_i
    end
    
    it "commits once to solr when the total number of solr documents is below the incremental commit threshold" do
      allow(@indexer).to receive(:get_all_changed_objects_for_branch).and_return(generate_fake_paths(@commit_every_n-1))
      allow(@indexer).to receive(:solrize_object).and_return({:id => 'foo', :title=>'bar'})
      expect(@indexer).to receive(:add_and_commit_to_solr).once
      expect(@indexer.index_druid_tree_branch(@branch).class).to eq(Array)
    end
    
    it "commits once to solr when the total number of solr documents is below the incremental commit threshold" do
      allow(@indexer).to receive(:get_all_changed_objects_for_branch).and_return(generate_fake_paths(@commit_every_n+1))
      allow(@indexer).to receive(:solrize_object).and_return({:id => 'foo', :title=>'bar'})
      expect(@indexer).to receive(:add_and_commit_to_solr).twice
      expect(@indexer.index_druid_tree_branch(@branch).class).to eq(Array)
    end
    
  end
  

  
  it "returns the path the deletes directory as a pathname" do
    expect(@indexer.path_to_deletes_dir.class).to eq(Pathname)
  end
  
  it "places the specified .deletes dir should be in the root of the purl directory" do
    expect(@indexer.path_to_deletes_dir.to_s.downcase).to eq("/purl/document_cache/.deletes")
  end

  it "gets the title from the mods file" do
    expect(@indexer.read_mods_for_object(@sample_doc_path)).to match({:title_tsi=>"This is Pete's New Test title for this object."})
  end
  
  it "raises an error when there is no mods" do
    expect{@indexer.read_mods_for_object(@sample_doc_path_files_missing)}.to raise_error(Errno::ENOENT)
  end
  
  it "gets the druid from identityMetadata" do
    expect(@indexer.get_druid_from_identityMetadata(@sample_doc_path)).to match("druid:bb050dj7711")
  end
  
  it "gets the druid from publicMetadata" do
    expect(@indexer.get_druid_from_publicMetadata(@sample_doc_path)).to match("druid:bb050dj7711")
  end
  
  it "raises an error when there is no identityMetadata" do
    expect{@indexer.get_druid_from_identityMetadata(@sample_doc_path_files_missing)}.to raise_error(Errno::ENOENT)
  end
  
  it "gets true and false data from the public xml regarding release status" do
    expect(@indexer.get_release_status(@sample_doc_path)).to match({:false => ["Atago"],:true => ["CARRICKR-TEST", "Robot_Testing_Feb_5_2015"]})
  end
  
  it "raises an error when there is no public xml" do
    expect{@indexer.get_release_status(@sample_doc_path_files_missing)}.to raise_error(Errno::ENOENT)
  end
  
  it "returns the doc hash when all needed files are present" do
    expect(@indexer.solrize_object(@sample_doc_path)).to match({:identityMetadata_objectType_t => ["item"], :false_releases_ssim => ["Atago"],:id => "druid:bb050dj7711", :title_tsi => "This is Pete's New Test title for this object.",:true_releases_ssim => ["CARRICKR-TEST", "Robot_Testing_Feb_5_2015"], :is_member_of_collection_s => ["druid:nt028fd5773", "druid:wn860zc7322"],})
  end
  
  it "returns the doc hash with no membership but a catkey for a top level collection that has a catkey" do
    expect(@indexer.solrize_object(@ct961sj2730_path)).to match({:title_tsi=>"Caroline Batchelor Map Collection.", :id=>"druid:ct961sj2730", :true_releases_ssim=>[], :false_releases_ssim=>[], :identityMetadata_objectType_t=>["collection", "set"], :catkey_tsi=>"10357851"})
  end
  
  it "returns the empty doc hash when it cannot open a file" do
   allow(@indexer.app_controller).to receive(:alert_squash).and_return(true)
   expect(@indexer.solrize_object(@sample_doc_path_files_missing)).to match({})
  end
  
  describe("Failure to find a needed file for building the solr document") do
    before :each do
      #Paths for copying
      @base_path = @sample_doc_path[0...-4]
      @source_dir = @base_path+"6667.src"
      @dest_dir = @source_dir[0...-4] #trim off the .src
      
      @druid = 'bb050dj6667'
      
      @druid_object = DruidTools::PurlDruid.new(@druid, @testing_doc_cache)
      FileUtils.cp_r  @source_dir, @dest_dir
      allow(@indexer).to receive(:purl_mount_location).and_return(@testing_doc_cache)
    end
    
    after :each do
      FileUtils.rm_r @dest_dir if File.directory?(@dest_dir) #remove the 6667 files
      remove_delete_records(@testing_doc_cache+File::SEPARATOR+'.deletes', ['bb050dj6667'])
    end
    
    it "logs an error, but swallows the exception when mods is not present" do
      allow(@indexer.app_controller).to receive(:alert_squash).and_return(true)
      remove_purl_file(@dest_dir, 'mods')
      expect(@indexer.log_object).to receive(:error).once
      expect(@indexer.solrize_object(@dest_dir)).to match({})
    end
    
    #This has been moved to pending due the fact we no longer have any core functions that raise an error when identityMetadata is not present
    xit "logs an error, but swallows the exception when identityMetadata is not present" do
      remove_purl_file(@dest_dir, 'identityMetadata')
      expect(@indexer.log_object).to receive(:error).once
      expect(@indexer.solrize_object(@dest_dir)).to match({})
    end
    
    it "logs an error, but swallows the exception when the public xml is not present" do
      allow(@indexer.app_controller).to receive(:alert_squash).and_return(true)
      remove_purl_file(@dest_dir, 'public')
      expect(@indexer.log_object).to receive(:error).once
      expect(@indexer.solrize_object(@dest_dir)).to match({})
    end
  end
    
  it "returns an RSolr Client when connecting to solr" do
    expect(@indexer.establish_solr_connection.class).to eq(RSolr::Client)
  end
  
  it "determines when the addition and commit of solr documents was successful" do
    VCR.use_cassette('submit_one_doc') do
      docs = [@indexer.solrize_object(@sample_doc_path)]
      expect(@indexer.add_and_commit_to_solr(docs)).to be_truthy
    end
  end
  
  it "determines when the solr commit was successful" do
    VCR.use_cassette('successful_solr_commit') do
      expect(@indexer.commit_to_solr(@indexer.establish_solr_connection)).to be_truthy
    end
  end
  
  it "determines from the RSolr response if the solr operation was successful" do
    resp = {"responseHeader"=>{"status"=>0, "QTime"=>77}} 
    expect(@indexer.parse_solr_response(resp)).to be_truthy
  end
  
  it "determines from the RSolr response if the solr operation failed" do
    resp = {"responseHeader"=>{"status"=>-1, "QTime"=>77}} 
    expect(@indexer.parse_solr_response(resp)).to be_falsey
  end
  
  it "determines from the RSolr response if the solr cloud is overloaded and sleeps the thread" do
    resp = {"responseHeader"=>{"status"=>0, "QTime"=>DorFetcherService::Application.config.solr_indexing['sleep_when_response_time_exceeds'].to_i}}
    begin_time = Time.now
    expect(@indexer.parse_solr_response(resp)).to be_truthy
    end_time = Time.now
    expect(end_time-begin_time).to be >= DorFetcherService::Application.config.solr_indexing['sleep_seconds_if_overloaded'].to_i
  end
  
  it "determines if the addition of solr documents was successful" do
    allow(@indexer.app_controller).to receive(:alert_squash).and_return(true)
    VCR.use_cassette('doc_submit_fails') do
      docs = [@indexer.solrize_object(@sample_doc_path)]
      expect(@indexer.add_and_commit_to_solr(docs)).to be_falsey
    end
  end
  
  it "determines if the solr commit was successful" do
    #FYI this will fail if you have your local solr running, because obviously you can connect to it 
    #It will also record a cassette and keep failing due to that cassette, but you need to keep this wrapped else VCR yells at you for connecting out
    #So if it fails, shut down local solr and delete the cassette, all tests should then pass since the other tests have cassettes 
    allow(@indexer.app_controller).to receive(:alert_squash).and_return(true)
    VCR.use_cassette('failed_solr_commit') do
      expect(@indexer.commit_to_solr(@indexer.establish_solr_connection)).to be_falsey
    end
  end
  
  it "returns the path to the delete directory as Pathname" do
    expect(@indexer.path_to_deletes_dir.class).to eq(Pathname)
  end
  
  it "adds the timestamp to documents" do 
    documents = @indexer.add_timestamp_to_documents([{},{}])
    expect(documents[0][:indexed_dtsi].class).to eq(String)
    expect(documents[1][:indexed_dtsi].class).to eq(String)
  end
  
  it "should return a string for the purl mount location" do
    expect(@indexer.purl_mount_location.class).to eq(String)
  end
  
  describe("deleting solr documents") do
    before :each do
      #Paths for copying
      @base_path = @sample_doc_path[0...-4]
      @source_dir = @base_path+"6667.src"
      @dest_dir = @source_dir[0...-4] #trim off the .src
      
      @druid = 'bb050dj6667'
      
      @druid_object = DruidTools::PurlDruid.new(@druid, @testing_doc_cache)
      FileUtils.cp_r  @source_dir, @dest_dir
      allow(@indexer).to receive(:purl_mount_location).and_return(@testing_doc_cache)
    end
    
    after :each do
      FileUtils.rm_r @dest_dir if File.directory?(@dest_dir) #remove the 6667 files
      remove_delete_records(@testing_doc_cache+File::SEPARATOR+'.deletes', ['bb050dj6667'])
    end
     
    it "detects that the druid is not deleted when its files are still present in the document cache" do
      expect(@indexer.is_deleted?(@druid)).to be_falsey
    end
    
    it "detects that the druid is deleted when its files are not present in the document cache" do
      FileUtils.rm_r @dest_dir #remove our testing druid
      expect(@indexer.is_deleted?(@druid)).to be_truthy
    end
    
    it "does not delete the test druid when the files still remain in the document cache" do
      #Delete the druid to create the .deletes dir record
      FileUtils.rm_r @dest_dir
      @druid_object.creates_delete_record
      #Copy the files back in
      FileUtils.cp_r  @source_dir, @dest_dir
      
      expect(@indexer.remove_deleted_objects_from_solr(mins_ago: 5)).to match({:success=>true, :docs=>[]})
      
    end
    
    it "deletes the druid from solr the files do not remain in the document cache" do
      allow(@indexer.app_controller).to receive(:alert_squash).and_return(true)
      #Index the druid into solr
      VCR.use_cassette('successful_solr_delete') do
        start_time = Time.now
        sleep(1) #make sure at least one second passes for the timestamp checks
        @indexer.add_and_commit_to_solr(@indexer.solrize_object(@dest_dir)) #commit 6667 to solr
        FileUtils.rm_r @dest_dir #remove its files
        @druid_object.creates_delete_record #create its delete record
        
        result = @indexer.remove_deleted_objects_from_solr(mins_ago: 5)
        sleep(1) #make sure at least one second passes for the timestamp checks
        end_time = Time.now
        #Check the result
        expect(result[:success]).to be_truthy
        expect(result[:docs].size).to eq(1)
        expect(result[:docs][0][:id]).to match("druid:bb050dj6667")
        expect(result[:docs][0][:deleted_tsi]).to match("true")  
        expect(result[:docs][0][:indexed_dtsi].class).to eq(String) #make sure it isn't a nill 
        
        #Make sure the index time stamp was set properly, it should be between the start time and end time
        index_time = Time.parse(result[:docs][0][:indexed_dtsi])
        expect(end_time > index_time).to be_truthy
        expect(start_time < index_time).to be_truthy
      end
      
      
    end
    
    it "detects multiple deletes in one pass" do
      fake_druids = ['bb050dj1817', 'bb050dj1885', 'bb050dj1971', 'bb050dj1927']
      
      fake_druids.each do |f_d|
        d_o = DruidTools::PurlDruid.new(f_d, @testing_doc_cache)
        d_o.creates_delete_record #Create the delete record, no files in the document_cache to delete except for 6667
      end
      FileUtils.rm_r @dest_dir #remove 6667 files
      
      VCR.use_cassette('multiple_druid_delete') do
        result = @indexer.remove_deleted_objects_from_solr(mins_ago: 5)
        expect(result[:success]).to be_truthy
        expect(result[:docs].size == fake_druids.size).to be_truthy
      end
      
      #Remove these delete records
      remove_delete_records(@testing_doc_cache+File::SEPARATOR+'.deletes', fake_druids)
      
    end
  end
  
  it "gets the object type" do
    expect(@indexer.get_objectType_from_identityMetadata(@sample_doc_path)).to match(['item'])
  end
  
  it "gets multiple object types when an object has multiple types" do
     @druid_object = DruidTools::PurlDruid.new('druid:ct961sj2730', @testing_doc_cache)
     expect(@indexer.get_objectType_from_identityMetadata( @druid_object.path)).to match(['collection','set'])
  end
  
  it "gets the collections and sets the object is a member of" do
    expect(@indexer.get_membership_from_publicxml(@sample_doc_path)).to match(['druid:nt028fd5773','druid:wn860zc7322'])
  end
  
  it "gets the cat key when one is present" do
    
    expect(@indexer.get_catkey_from_identityMetadata(@ct961sj2730_path)).to match('10357851')
  end
  
  it "returns empty string when no cat key is present" do
    expect(@indexer.get_catkey_from_identityMetadata(@sample_doc_path)).to match('')
  end
  
  #Warning this block of tests can take some time due to the fact that you need to sleep for at least a minute for the find command
  describe("Detecting changes to the file system") do
      before :each do
         #Paths for copying
         @base_path = @sample_doc_path[0...-4]
         @source_dir = @base_path+"6667.src"
         @dest_dir = @source_dir[0...-4] #trim off the .src

         allow(@indexer).to receive(:purl_mount_location).and_return(@testing_doc_cache)
         allow(@indexer).to receive(:add_and_commit_to_solr).and_return({"responseHeader"=>{"status"=>0, "QTime"=>36}}) #fake the solr commit part, we test that elsewhere
       end

    #Multiple functions are tested here to avoid having to repeat the sleep 
    #This tests:
    # index_all_modified_objects
    # index_druid_tree_branch  
    # get_all_changed_objects_for_branch
    #
    it "detects when a purl has been changed" do 
      FileUtils.rm_r @dest_dir if File.directory?(@dest_dir) #If this test failed and isreun, clear the directory 
      branch = purl_fixture_path+File::SEPARATOR+'bb'
      @indexer.instance_variable_set(:@modified_at_or_later, 1) #Set the default mod time to one minute
      sleep(61)
            
      
      #Now nothing has changed in the last minute so when we search for things modified a minute ago, nothing should pop up
      expect(@indexer.index_all_modified_objects(mins_ago: 1)[:docs]).to match([]) #nothing has changed in the last minute
      expect(@indexer.index_druid_tree_branch(branch)).to match([]) 
      expect(@indexer.get_all_changed_objects_for_branch(branch)).to match([])
      
      #Make sure we filter only on files we want
      empty_file = @sample_doc_path+File::SEPARATOR+'my_updates_do_not_count'
      FileUtils.touch(@sample_doc_path+File::SEPARATOR+'my_updates_do_not_count') #add in a fake files who change should not trigger
      
      #Since this file does not matter, no function should pick up on it as a reason to update something
      expect(@indexer.index_all_modified_objects(mins_ago: 1)[:docs]).to match([])
      expect(@indexer.index_druid_tree_branch(branch)).to match([]) 
      expect(@indexer.get_all_changed_objects_for_branch(branch)).to match([])
      
      
      #Simulate republishing the purl
      FileUtils.rm_r @dest_dir if File.directory?(@dest_dir)
      FileUtils.cp_r  @source_dir, @dest_dir 
      
      #We should see this one file as a change
      r= @indexer.index_all_modified_objects(mins_ago: 1)
      expect(r[:docs].size).to eq(1)
      expect(@indexer.index_druid_tree_branch(branch).size).to eq(1) #sweeping the branch returns the object that changed
      expect(@indexer.get_all_changed_objects_for_branch(branch).size).to eq(1)
      
      #The index_all_modified_objects should sweep across all branches, so touch something in another branch
      FileUtils.touch(@ct961sj2730_path+File::SEPARATOR+'mods')
      r = @indexer.index_all_modified_objects(mins_ago: 1)
      expect(r[:docs].size).to eq(2) #The bb and ct branches should now have a total of two modified
      
      #Clear the temp file back out
      FileUtils.rm empty_file
      FileUtils.rm_r @dest_dir if File.directory?(@dest_dir)
    end 
  end
  
  describe("deleting documents from solr") do
    before :all do
       @testing_solr_connection = RSolr.connect
    end
    
    it "calls rsolr delete by id" do
        expect(@indexer).to receive(:establish_solr_connection).once.and_return(@testing_solr_connection)
        expect(@testing_solr_connection).to receive(:delete_by_id).once.and_return({})
        expect(@indexer).to receive(:commit_to_solr).once.and_return(true)
        expect(@indexer).to receive(:parse_solr_response).once.and_return(true) #fake a successful call
        expect(@indexer.delete_document('foo')).to be_truthy
    end
    
    it "logs an error when rsolr cannot delete something" do
      allow(@indexer.app_controller).to receive(:alert_squash).and_return(true)
      expect(@indexer).to receive(:establish_solr_connection).once.and_return(@testing_solr_connection)
      expect(@indexer.log_object).to receive(:error).once
      allow(@testing_solr_connect).to receive(:delete_by_id).and_raise(RSolr::Error)
      expect(@indexer.delete_document('foo')).to be_falsey
    end
    
    it "logs an error when rslor cannot commit after a delete operation" do
      allow(@indexer.app_controller).to receive(:alert_squash).and_return(true)
      expect(@indexer).to receive(:establish_solr_connection).once.and_return(@testing_solr_connection)
      expect(@testing_solr_connection).to receive(:delete_by_id).once.and_return({})
      expect(@indexer).to receive(:commit_to_solr).once.and_return(false)
      expect(@indexer.log_object).to receive(:error).once
      expect(@indexer).to receive(:parse_solr_response).once.and_return(true) #fake a successful call
      expect(@indexer.delete_document('foo')).to be_falsey
    end
    
  end
  
end