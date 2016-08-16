require 'rails_helper'

describe PurlFinder do
  let(:purl_finder) { described_class.new }
  let(:sample_doc_path_files_missing) { DruidTools::PurlDruid.new('bb050dj0000', purl_fixture_path).path }
  let(:ct961sj2730_path) { DruidTools::PurlDruid.new('ct961sj2730', purl_fixture_path).path } # this one has a catkey and is a top level collection
  let(:druid_object) { DruidTools::PurlDruid.new('bb050dj6667', purl_fixture_path) }

  describe('finder setup') do
    it 'gets the druid from the file path' do
      expect(purl_finder.get_druid_from_file_path(sample_doc_path)).to eq('bb050dj7711')
    end

    it 'gets the druid from the delete file path' do
      expect(purl_finder.get_druid_from_delete_path(File.join(purl_finder.path_to_deletes_dir, 'ct961sj2730'))).to eq('ct961sj2730')
    end

    it 'returns the base path finder log location' do
      expect(purl_finder.base_path_finder_log).to eq(File.join(Rails.root, 'log'))
    end

    it 'returns the base path filename finder log' do
      expect(purl_finder.base_filename_finder_log).to eq('purl_finder')
    end

    it 'returns a string for the purl mount location' do
      expect(purl_finder.purl_mount_location.class).to eq(String)
    end

    it 'returns the path to a purl file location given a druid' do
      expect(purl_finder.purl_path("druid:bb050dj7711")).to eq(File.join(purl_finder.purl_mount_location, 'bb/050/dj/7711'))
    end

    it 'returns the path the deletes directory as a string and has the correct location' do
      expect(purl_finder.path_to_deletes_dir).to match /\.deletes/
      expect(purl_finder.path_to_deletes_dir.class).to eq(String)
    end

    it 'returns the default output finder file location' do
      expect(purl_finder.default_output_file).to eq(File.join(Rails.root, 'log/purl_finder'))
    end
  end

  describe('Indexing/finding') do
    before :each do
      allow(purl_finder).to receive(:purl_mount_location).and_return(purl_fixture_path)
    end

    # some cleanup that occurs after tests are run
    after :all do
      delete_dir(test_purl_dest_dir)
      delete_file(empty_file)
    end

    describe('deleting documents') do
      let(:druid) { 'bb050dj6667' }
      before :each do
        FileUtils.cp_r test_purl_source_dir, test_purl_dest_dir
      end

      after :each do
        delete_dir(test_purl_dest_dir) # remove the temporary purl
        remove_delete_records(File.join(purl_fixture_path, '.deletes'), ['bb050dj6667']) # remove the deleted record
      end

      it 'logs an error, but swallows the exception when the public xml is not present' do
        remove_purl_file(test_purl_dest_dir, 'public')
        expect(IndexingLogger).to receive(:error).once
        expect(Purl.save_from_public_xml(test_purl_dest_dir)).to be_falsey
      end

      it 'detects that the druid public xml exists when its files are still present in the document cache' do
        expect(purl_finder.public_xml_exists?(druid)).to be_truthy
      end

      it 'detects that the druid is deleted (public xml does not exists) when its files are not present in the document cache' do
        delete_dir(test_purl_dest_dir) # remove our testing druid
        expect(purl_finder.public_xml_exists?(druid)).to be_falsey
      end

      it 'does not delete the test druid when the files still remain in the document cache' do
        # Delete the druid to create the .deletes dir record
        delete_dir(test_purl_dest_dir)
        druid_object.creates_delete_record
        # Copy the files back in, this puts the public XML file in place, even though the deletes record is there
        FileUtils.cp_r test_purl_source_dir, test_purl_dest_dir
        expect(Purl).not_to receive(:mark_deleted)
        expect(purl_finder.remove_deleted(mins_ago: 5)).to match(count: 0, success: 0, error: 0) # nothing should happen
      end

      it 'saves a druid, then marks the druid as deleted, then resaves it correctly' do
        index_start_time = Time.zone.now
        Purl.save_from_public_xml(test_purl_dest_dir) # add the purl to the database
        index_end_time = Time.zone.now
        expect(Purl.all.count).to eq(num_purl_fixtures_in_database + 1) # now we have one more record in the database
        purl = Purl.find_by_druid('druid:bb050dj6667')
        expect(purl.druid).to eq('druid:bb050dj6667') # confirm the druid
        expect(purl.deleted_at?).to be_falsey # it is not deleted

        delete_dir(test_purl_dest_dir) # remove its files
        delete_file = druid_object.creates_delete_record.first # create its delete record
        expect(IndexingLogger).to receive(:info).with(/deleting/).once
        expect(Purl).to receive(:mark_deleted).with(/bb050dj6667/, Pathname(delete_file).mtime).and_call_original
        result = purl_finder.remove_deleted # delete it
        expect(result).to be_truthy
        expect(Purl.all.count).to eq(num_purl_fixtures_in_database + 1) # still just have one more record in the database
        purl = Purl.find_by_druid('druid:bb050dj6667')
        expect(purl.druid).to eq('druid:bb050dj6667') # confirm the druid
        expect(purl.deleted_at?).to be_truthy # it is deleted

        FileUtils.cp_r test_purl_source_dir, test_purl_dest_dir # put the purl back
        Purl.save_from_public_xml(test_purl_dest_dir) # re-add the purl to the database
        expect(Purl.all.count).to eq(num_purl_fixtures_in_database + 1) # confirm we still have one record in the database
        purl = Purl.find_by_druid('druid:bb050dj6667')
        expect(purl.druid).to eq('druid:bb050dj6667') # confirm the druid
        expect(purl.deleted_at?).to be_falsey # it is not marked as deleted now
      end

      it 'detects multiple deletes in one pass' do
        fake_druids = ['bb050dj1817', 'bb050dj1885', 'bb050dj1971', 'bb050dj1927']

        fake_druids.each do |f_d|
          d_o = DruidTools::PurlDruid.new(f_d, purl_fixture_path)
          d_o.creates_delete_record # Create the delete record, no files in the document_cache to delete except for 6667
        end
        delete_dir(test_purl_dest_dir) # remove 6667 files

        result = purl_finder.remove_deleted(mins_ago: 5)
        expect(result).to eq(count: fake_druids.size, success: fake_druids.size, error: 0)

        # Remove these delete records
        remove_delete_records(File.join(purl_fixture_path, '.deletes'), fake_druids)
      end
    end

    # Warning this block of tests can take some time due to the fact that you need to sleep for at least a minute for the find command
    describe('Finding changed files on the purl mount') do
      after :each do
        # Clear the temp file and purl back out
        delete_file(empty_file)
        delete_dir(test_purl_dest_dir)
      end

      # this method includes a sleep command since we need to be sure the time based finding works correctly
      it 'finds public files correctly using time constraints' do
        sleep(61)

        # Nothing has changed in the last minute so when we search for things modified a minute ago, nothing should pop up
        finder_file_test(mins_ago: 1, expected_num_files_found: 0)

        # # Make sure we filter only on files we want
        FileUtils.touch(empty_file) # add in a fake files who change should not trigger
        # # Since this file does not matter, it should not be found, even though it was updated less than 1 minute ago
        finder_file_test(mins_ago: 1, expected_num_files_found: 0)

        # Add a new purl
        FileUtils.cp_r test_purl_source_dir, test_purl_dest_dir

        # # We should see this one file as a change
        purl_finder.find_files(mins_ago: 1)
        finder_file_test(mins_ago: 1, expected_num_files_found: 1)

        # # Touch an existing purl in another branch
        FileUtils.touch(File.join(ct961sj2730_path, 'public'))
        purl_finder.find_files(mins_ago: 1)
        finder_file_test(mins_ago: 1, expected_num_files_found: 2) # we now have 2 files
      end

      it 'finds public files correctly using no time constraints' do
        # When you don't send a specific mins_ago param, it should find everything
        finder_file_test(mins_ago: nil, expected_num_files_found: 2)

        # # Make sure we filter only on files we want
        FileUtils.touch(empty_file) # add in a fake files who change should not trigger
        # # Since this file does not matter, it should not be found
        finder_file_test(mins_ago: nil, expected_num_files_found: 2)

        # add another purl
        FileUtils.cp_r test_purl_source_dir, test_purl_dest_dir

        # # We now have a new file
        finder_file_test(mins_ago: nil, expected_num_files_found: 3)

        # Clear the temp file and purl back out
        delete_file(empty_file)
        delete_dir(test_purl_dest_dir)

        # back to 2 files
        finder_file_test(mins_ago: nil, expected_num_files_found: 2)
      end
    end

    describe('indexing purls') do
      it 'does not start a new indexing run if one is already running according to the run logs' do
        expect(RunLog.count).to eq(0)
        expect(RunLog.currently_running?).to be_falsey
        r = RunLog.create(started: Time.zone.now)
        expect(RunLog.currently_running?).to be_truthy
        expect(purl_finder).not_to receive(:index_purls)
        expect(purl_finder.find_and_index).to be_falsey # it doesn't run
        r.ended = Time.zone.now
        r.save
        expect(RunLog.currently_running?).to be_falsey
      end

      it 'indexes and re-indexes purls correctly' do
        expect(Purl.all.count).to eq(num_purl_fixtures_in_database) # no extra purls in the database yet
        expect(RunLog.currently_running?).to be_falsey
        expect(RunLog.count).to eq(0)
        index_counts = purl_finder.full_reindex # this will run both a find and an index operation, although we really just need to test index at this point
        expect(index_counts[:count]).to eq(2)
        expect(index_counts[:success]).to eq(2)
        expect(index_counts[:error]).to eq(0)
        # Confirm results against the database
        expect(Purl.all.count).to eq(num_purl_fixtures_in_database + 2) # two extra items indexed
        indexed_druids = ["druid:bb050dj7711", "druid:ct961sj2730"]
        all_druids = indexed_druids + fixture_druids_in_database
        expect(Purl.all.map(&:druid).sort).to eq(all_druids.sort) # sort so we do not have to worry about ordering, just if they match the expected druids
        expect(RunLog.count).to eq(1)
        expect(RunLog.currently_running?).to be_falsey

        # now try to reindex the previous run
        reindex_counts = purl_finder.reindex(RunLog.last.id)
        expect(reindex_counts[:count]).to eq(2)
        expect(reindex_counts[:success]).to eq(2)
        expect(reindex_counts[:error]).to eq(0)
        # Still only two purls in the database, no new ones were created
        expect(Purl.all.count).to eq(num_purl_fixtures_in_database + 2) # still two extra items
        expect(RunLog.count).to eq(1) # no new run logs, since we didn't run a find
        expect(RunLog.currently_running?).to be_falsey
      end

      it 'finds and indexes public files correctly since the last run' do
        allow(purl_finder).to receive(:find_and_index).and_return({}) # stub the call out so it is not actually made just for this test
        last_run_min_ago = 10

        # simulate a recent run that started a specified minutes ago
        RunLog.create(started: Time.zone.now - last_run_min_ago.minutes, ended: Time.zone.now - (last_run_min_ago / 2).minutes, total_druids: 2, finder_filename: purl_finder.default_output_file)
        expect(RunLog.minutes_since_last_run_started).to eq(last_run_min_ago + 1)

        # reindex new stuff, and check the correct call was made (there is a separate test for the actual find_and_index call)
        expect(purl_finder).to receive(:find_and_index).once.with(mins_ago: last_run_min_ago + 1)
        purl_finder.index_since_last_run
      end
    end
  end
  describe '#index_purls' do
    it 'catches and records an error from Purl#save_from_public_xml' do
      expect(Purl).to receive(:save_from_public_xml).twice.and_raise(StandardError)
      expect(IndexingLogger).to receive(:error).twice.with(/An error occurred/)
      expect(described_class.new.index_purls(output_path: 'dev/null/bad/path')).to include(count: 2, success: 0, error: 2)
    end
  end
end
