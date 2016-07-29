require 'rails_helper'

describe Indexer do
  let(:indexer) { Indexer.new }
  let(:sample_doc_path) { DruidTools::PurlDruid.new('bb050dj7711', testing_doc_cache).path }
  let(:testing_doc_cache) { purl_fixture_path }
  let(:sample_doc_path_files_missing) { DruidTools::PurlDruid.new('bb050dj0000', testing_doc_cache).path }
  let(:ct961sj2730_path) { DruidTools::PurlDruid.new('ct961sj2730', testing_doc_cache).path } # this one has a catkey and is a top level collection

  # Paths for copying
  let(:base_path) { sample_doc_path[0...-4] }
  let(:source_dir) { base_path + '6667.src' }
  let(:dest_dir) { source_dir[0...-4] } # trim off the .src

  let(:druid_object) { DruidTools::PurlDruid.new('bb050dj6667', testing_doc_cache) }

  describe('testing connectivity to the solr core') do
    let(:s_c) { indexer.solr_connection }
    it 'returns true when the solr core responds to a select' do
      allow(indexer).to receive(:solr_connection).and_return(s_c)
      allow(s_c).to receive(:get).and_return('responseHeader' => { 'status' => 0 })
      expect(indexer.check_solr_core).to be_truthy
    end

    it 'returns false when the solr core does not respond to a select' do
      allow(indexer).to receive(:solr_connection).and_return(s_c)
      allow(s_c).to receive(:get).and_return('responseHeader' => { 'status' => 1 })
      expect(indexer.check_solr_core).to be_falsey
    end
  end

  it 'gets the druid from the file path' do
    expect(indexer.get_druid_from_file_path(sample_doc_path)).to eq('bb050dj7711')
  end

  it 'returns the base path finder log location' do
    expect(indexer.base_path_finder_log).to eq(File.join(Rails.root,'tmp'))
  end

  it 'returns the base path filename finder log' do
    expect(indexer.base_filename_finder_log).to eq('purl_finder')
  end

  it 'returns the commit every parameter' do
    expect(indexer.commit_every).to eq(50)
  end

  it 'returns the default modified_at_or_later parameter' do
    expect(indexer.modified_at_or_later).to be <= indexer.indexer_config['default_run_interval_in_minutes'].to_i.minutes.ago
  end

  it 'returns the path to a purl file location given a druid' do
    expect(indexer.purl_path("druid:bb050dj7711")).to eq(File.join(indexer.purl_mount_location,'bb/050/dj/7711'))
  end

  it 'returns the path the deletes directory as a pathname' do
    expect(indexer.path_to_deletes_dir.class).to eq(Pathname)
  end

  it 'places the specified .deletes dir should be in the root of the purl directory' do
    expect(indexer.path_to_deletes_dir.to_s.downcase).to eq('/purl/document_cache/.deletes')
  end

  it 'returns the doc hash when all needed files are present' do
    expect(indexer.solrize_object(sample_doc_path)).to match(objectType_ssim: ['item'],
                                                             false_releases_ssim: ['Atago'],
                                                             id: 'druid:bb050dj7711',
                                                             title_tesim: "This is Pete's New Test title for this object.",
                                                             true_releases_ssim: ['CARRICKR-TEST', 'Robot_Testing_Feb_5_2015'],
                                                             is_member_of_collection_ssim: ['druid:nt028fd5773', 'druid:wn860zc7322'])
  end

  it 'returns the doc hash with no membership but a catkey for a top level collection that has a catkey' do
    expect(indexer.solrize_object(ct961sj2730_path)).to match(title_tesim: 'Caroline Batchelor Map Collection.',
                                                              id: 'druid:ct961sj2730',
                                                              true_releases_ssim: [],
                                                              false_releases_ssim: [],
                                                              objectType_ssim: ['collection', 'set'],
                                                              catkey_id_ssim: '10357851')
  end

  it 'returns the empty doc hash when it cannot open a file' do
    allow_message_expectations_on_nil
    expect(indexer.solrize_object(sample_doc_path_files_missing)).to match({})
  end

  describe('Failure to find a needed file for building the solr document') do
    before :each do
      FileUtils.cp_r source_dir, dest_dir
      allow(indexer).to receive(:purl_mount_location).and_return(testing_doc_cache)
    end

    after :each do
      FileUtils.rm_r dest_dir if File.directory?(dest_dir) # remove the 6667 files
      remove_delete_records(File.join(testing_doc_cache,'.deletes'), ['bb050dj6667'])
    end

    it 'logs an error, but swallows the exception when the public xml is not present' do
      allow_message_expectations_on_nil
      remove_purl_file(dest_dir, 'public')
      expect(IndexingLogger).to receive(:error).once
      expect(indexer.solrize_object(dest_dir)).to match({})
    end
  end

  it 'returns an RSolr Client when connecting to solr' do
    expect(indexer.solr_connection.class).to eq(RSolr::Client)
  end

  it 'determines when the addition and commit of solr documents was successful' do
    VCR.use_cassette('submit_one_doc') do
      doc = indexer.solrize_object(sample_doc_path)
      expect(IndexingLogger).to receive(:info).with(/Processing item.*adding/).once
      expect(indexer.add_to_solr(doc)).to be_truthy
    end
  end

  it 'determines when the solr commit was successful' do
    VCR.use_cassette('successful_solr_commit') do
      expect(indexer.commit_to_solr).to be_truthy
    end
  end

  it 'determines from the RSolr response if the solr operation was successful' do
    resp = { 'responseHeader' => { 'status' => 0, 'QTime' => 77 } }
    expect(indexer.parse_solr_response(resp)).to be_truthy
  end

  it 'determines from the RSolr response if the solr operation failed' do
    resp = { 'responseHeader' => { 'status' => -1, 'QTime' => 77 } }
    expect(indexer.parse_solr_response(resp)).to be_falsey
  end

  it 'determines from the RSolr response if the solr cloud is overloaded and sleeps the thread' do
    resp = { 'responseHeader' => { 'status' => 0, 'QTime' => PurlFetcher::Application.config.solr_indexing['sleep_when_response_time_exceeds'].to_i } }
    begin_time = Time.zone.now
    expect(indexer.parse_solr_response(resp)).to be_truthy
    end_time = Time.zone.now
    expect(end_time - begin_time).to be >= PurlFetcher::Application.config.solr_indexing['sleep_seconds_if_overloaded'].to_i
  end

  it 'determines if the addition of solr documents was successful' do
    # FYI this will fail if you have your local solr running, because obviously you can connect to it
    # It will also record a cassette and keep failing due to that cassette, but you need to keep this wrapped else VCR yells at you for connecting out
    # So if it fails, shut down local solr and delete the cassette, all tests should then pass since the other tests have cassettes
    allow_message_expectations_on_nil
    VCR.use_cassette('doc_submit_fails') do
      doc = indexer.solrize_object(sample_doc_path)
      expect(indexer.add_to_solr(doc)).to be_falsey
    end
  end

  it 'determines if the solr commit was successful' do
    # FYI this will fail if you have your local solr running, because obviously you can connect to it
    # It will also record a cassette and keep failing due to that cassette, but you need to keep this wrapped else VCR yells at you for connecting out
    # So if it fails, shut down local solr and delete the cassette, all tests should then pass since the other tests have cassettes
    allow_message_expectations_on_nil
    VCR.use_cassette('failed_solr_commit') do
      expect(indexer.commit_to_solr).to be_falsey
    end
  end

  it 'returns the path to the delete directory as Pathname' do
    expect(indexer.path_to_deletes_dir.class).to eq(Pathname)
  end

  it 'returns a string for the purl mount location' do
    expect(indexer.purl_mount_location.class).to eq(String)
  end

  describe('deleting solr documents') do
    let(:druid) { 'bb050dj6667' }
    before :each do
      FileUtils.cp_r source_dir, dest_dir
      allow(indexer).to receive(:purl_mount_location).and_return(testing_doc_cache)
    end

    after :each do
      FileUtils.rm_r dest_dir if File.directory?(dest_dir) # remove the 6667 files
      remove_delete_records(File.join(testing_doc_cache,'.deletes'), ['bb050dj6667'])
    end

    it 'detects that the druid is not deleted when its files are still present in the document cache' do
      expect(indexer.deleted?(druid)).to be_falsey
    end

    it 'detects that the druid is deleted when its files are not present in the document cache' do
      FileUtils.rm_r dest_dir # remove our testing druid
      expect(indexer.deleted?(druid)).to be_truthy
    end

    it 'does not delete the test druid when the files still remain in the document cache' do
      # Delete the druid to create the .deletes dir record
      FileUtils.rm_r dest_dir
      druid_object.creates_delete_record
      # Copy the files back in
      FileUtils.cp_r source_dir, dest_dir

      expect(indexer.remove_deleted_objects_from_solr(mins_ago: 5)).to match(success: true, docs: [])
    end

    it 'deletes the druid from solr the files do not remain in the document cache' do
      allow_message_expectations_on_nil
      # Index the druid into solr
      VCR.use_cassette('successful_solr_delete') do
        start_time = Time.zone.now
        sleep(1) # make sure at least one second passes for the timestamp checks
        indexer.add_to_solr(indexer.solrize_object(dest_dir)) # commit 6667 to solr
        indexer.commit_to_solr
        FileUtils.rm_r dest_dir # remove its files
        druid_object.creates_delete_record # create its delete record

        expect(IndexingLogger).to receive(:info).with(/Processing item.*deleting/).once
        result = indexer.remove_deleted_objects_from_solr(mins_ago: 5)
        sleep(1) # make sure at least one second passes for the timestamp checks
        end_time = Time.zone.now
        # Check the result
        expect(result[:success]).to be_truthy
        expect(result[:docs].size).to eq(1)
        expect(result[:docs][0][:id]).to match('druid:bb050dj6667')
        expect(result[:docs][0][:deleted_tsi]).to match('true')
        expect(result[:docs][0][:indexed_dtsi].class).to eq(String) # make sure it isn't a nill

        # Make sure the index time stamp was set properly, it should be between the start time and end time
        index_time = Time.zone.parse(result[:docs][0][:indexed_dtsi])
        expect(end_time > index_time).to be_truthy
        expect(start_time < index_time).to be_truthy
      end
    end

    it 'detects multiple deletes in one pass' do
      fake_druids = ['bb050dj1817', 'bb050dj1885', 'bb050dj1971', 'bb050dj1927']

      fake_druids.each do |f_d|
        d_o = DruidTools::PurlDruid.new(f_d, testing_doc_cache)
        d_o.creates_delete_record # Create the delete record, no files in the document_cache to delete except for 6667
      end
      FileUtils.rm_r dest_dir # remove 6667 files

      VCR.use_cassette('multiple_druid_delete') do
        result = indexer.remove_deleted_objects_from_solr(mins_ago: 5)
        expect(result[:success]).to be_truthy
        expect(result[:docs].size == fake_druids.size).to be_truthy
      end

      # Remove these delete records
      remove_delete_records(File.join(testing_doc_cache,'.deletes'), fake_druids)
    end
  end

  # Warning this block of tests can take some time due to the fact that you need to sleep for at least a minute for the find command
  describe('Detecting changes to the file system') do
    before :each do
      allow(indexer).to receive(:purl_mount_location).and_return(testing_doc_cache)
      allow(indexer).to receive(:commit_to_solr).and_return('responseHeader' => { 'status' => 0, 'QTime' => 36 }) # fake the solr commit part, we test that elsewhere
    end

    # Multiple functions are tested here to avoid having to repeat the sleep
    # This tests:
    # index_all_modified_objects
    # index_druid_tree_branch
    # get_all_changed_objects_for_branch
    #
    it 'detects when a purl has been changed' do
      skip 'there is a race condition or something that causes this test to fail sporadically'
      FileUtils.rm_r dest_dir if File.directory?(dest_dir) # If this test failed and isreun, clear the directory
      branch = File.join(purl_fixture_path,'bb')
      indexer.instance_variable_set(:@modified_at_or_later, 1) # Set the default mod time to one minute
      sleep(61)

      # Now nothing has changed in the last minute so when we search for things modified a minute ago, nothing should pop up
      expect(indexer.index_all_modified_objects(mins_ago: 1)[:docs]).to match([]) # nothing has changed in the last minute
      expect(indexer.index_druid_tree_branch(branch)).to match([])
      expect(indexer.get_all_changed_objects_for_branch(branch)).to match([])

      # Make sure we filter only on files we want
      empty_file = File.join(sample_doc_path,'my_updates_do_not_count')
      FileUtils.touch(empty_file) # add in a fake files who change should not trigger

      # Since this file does not matter, no function should pick up on it as a reason to update something
      expect(indexer.index_all_modified_objects(mins_ago: 1)[:docs]).to match([])
      expect(indexer.index_druid_tree_branch(branch)).to match([])
      expect(indexer.get_all_changed_objects_for_branch(branch)).to match([])

      # Simulate republishing the purl
      FileUtils.rm_r dest_dir if File.directory?(dest_dir)
      FileUtils.cp_r source_dir, dest_dir

      # We should see this one file as a change
      r = indexer.index_all_modified_objects(mins_ago: 1)
      expect(r[:docs].size).to eq(1)
      expect(indexer.index_druid_tree_branch(branch).size).to eq(1) # sweeping the branch returns the object that changed
      expect(indexer.get_all_changed_objects_for_branch(branch).size).to eq(1)

      # The index_all_modified_objects should sweep across all branches, so touch something in another branch
      FileUtils.touch(File.join(ct961sj2730_path,'mods'))
      r = indexer.index_all_modified_objects(mins_ago: 1)
      expect(r[:docs].size).to eq(2) # The bb and ct branches should now have a total of two modified

      # Clear the temp file back out
      FileUtils.rm empty_file
      FileUtils.rm_r dest_dir if File.directory?(dest_dir)
    end
  end

  describe('deleting documents from solr') do
    let(:testing_solr_connection) { RSolr.connect }

    it 'calls rsolr delete by id' do
      expect(indexer).to receive(:solr_connection).once.and_return(testing_solr_connection)
      expect(testing_solr_connection).to receive(:delete_by_id).once.and_return({})
      expect(indexer).to receive(:commit_to_solr).once.and_return(true)
      expect(indexer).to receive(:parse_solr_response).once.and_return(true) # fake a successful call
      expect(indexer.delete_document('foo')).to be_truthy
    end

    it 'logs an error when rsolr cannot delete something' do
      allow_message_expectations_on_nil
      expect(indexer).to receive(:solr_connection).once.and_return(testing_solr_connection)
      expect(IndexingLogger).to receive(:error).once
      allow(testing_solr_connection).to receive(:delete_by_id).and_raise(RSolr::Error)
      expect(indexer.delete_document('foo')).to be_falsey
    end

    it 'logs an error when rslor cannot commit after a delete operation' do
      allow_message_expectations_on_nil
      expect(indexer).to receive(:solr_connection).once.and_return(testing_solr_connection)
      expect(testing_solr_connection).to receive(:delete_by_id).once.and_return({})
      expect(indexer).to receive(:commit_to_solr).once.and_return(false)
      expect(IndexingLogger).to receive(:error).once
      expect(indexer).to receive(:parse_solr_response).once.and_return(true) # fake a successful call
      expect(indexer.delete_document('foo')).to be_falsey
    end
  end

  describe('solr_connection') do
    let(:testing_solr_connection) { RSolr.connect }

    it 'logs an error when it cannot query solr and returns an empty hash' do
      allow(indexer).to receive(:solr_connection).and_return(testing_solr_connection)
      allow(testing_solr_connection).to receive(:get).and_raise(RSolr::Error)
      expect(IndexingLogger).to receive(:error).once
      expect(indexer.run_solr_query('whatever')).to match({})
    end
  end

end
