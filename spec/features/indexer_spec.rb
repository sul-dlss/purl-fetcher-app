require 'rails_helper'

describe("Indexer lib")  do
  include ApplicationHelper
  
  before :each do
    @indexer = IndexerTester.new
    @testing_doc_cache = Rails.root.to_s + (File::SEPARATOR+'spec'+File::SEPARATOR+'purl'+File::SEPARATOR+'document_cache')
    @sample_docs =  @testing_doc_cache + (File::SEPARATOR+'bb'+File::SEPARATOR+'050'+File::SEPARATOR+'dj'+File::SEPARATOR+'7711')
    @sample_docs_files_missing = (File::SEPARATOR+'bb'+File::SEPARATOR+'050'+File::SEPARATOR+'dj'+File::SEPARATOR+'0000')
  end
  
  it "returns the path the deletes directory as a pathname" do
    expect(@indexer.path_to_deletes_dir.class).to eq(Pathname)
  end
  
  it "places the specified .deletes dir should be in the root of the purl directory" do
    expect(@indexer.path_to_deletes_dir.to_s.downcase).to eq("/purl/document_cache/.deletes")
  end
  
  xit "gets all changed directory in a branch and returns one reference to each object directory" do
    #TODO:  Figure out how to work touch times and make this test not take forever
  end
  
  it "gets the title from the mods file" do
    expect(@indexer.read_mods_for_object(@sample_docs)).to match({:title_tsi=>"This is Pete's New Test title for this object."})
  end
  
  it "raises an error when there is no mods" do
    expect{@indexer.read_mods_for_object(@sample_docs_files_missing)}.to raise_error(Errno::ENOENT)
  end
  
  it "gets the druid from identityMetadata" do
    expect(@indexer.get_druid_from_identityMetadata(@sample_docs)).to match("druid:bb050dj7711")
  end
  
  it "raises an error when there is no identityMetadata" do
    expect{@indexer.get_druid_from_identityMetadata(@sample_docs_files_missing)}.to raise_error(Errno::ENOENT)
  end
  
  it "gets true and false data from the public xml regarding release status" do
    expect(@indexer.get_release_status(@sample_docs)).to match({:false => ["Atago"],:true => ["CARRICKR-TEST", "Robot_Testing_Feb_5_2015"]})
  end
  
  it "raises an error when there is no public xml" do
    expect{@indexer.get_release_status(@sample_docs_files_missing)}.to raise_error(Errno::ENOENT)
  end
  
  it "returns the doc hash when all needed files are present" do
    expect(@indexer.solrize_object(@sample_docs)).to match({:false_releases_ssim => ["Atago"],:id => "druid:bb050dj7711", :title_tsi => "This is Pete's New Test title for this object.",:true_releases_ssim => ["CARRICKR-TEST", "Robot_Testing_Feb_5_2015"]})
  end
  
  it "returns the empty doc hash when it cannot open a file" do
   expect(@indexer.solrize_object(@sample_docs_files_missing)).to match({})
  end
  
  xit "logs an error when a file cannot be found for a purl object" do
  end
  
  it "returns an RSolr Client when connecting to solr" do
    expect(@indexer.establish_solr_connection.class).to eq(RSolr::Client)
  end
  
  it "determines when the addition and commit of solr documents was successful" do
    VCR.use_cassette('submit_one_doc') do
      docs = [@indexer.solrize_object(@sample_docs)]
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
    VCR.use_cassette('doc_submit_fails') do
      docs = [@indexer.solrize_object(@sample_docs)]
      expect(@indexer.add_and_commit_to_solr(docs)).to be_falsey
    end
  end
  
  it "determines if the solr commit was successful" do
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
  
  xit "queries solr for documents modified between two timestaps" do
  end
  
  xit "returns an empty array when its query to solr for documents between two timestamps fails" do
  end
  
  xit "formats the solr response of documents properly" do
  end
  
end