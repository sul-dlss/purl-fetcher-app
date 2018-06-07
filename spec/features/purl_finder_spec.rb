require 'rails_helper'

describe PurlFinder do
  let(:purl_finder) { described_class.new }
  let(:sample_doc_path_files_missing) { DruidTools::PurlDruid.new('bb050dj0000', purl_fixture_path).path }
  let(:ct961sj2730_path) { DruidTools::PurlDruid.new('ct961sj2730', purl_fixture_path).path } # this one has a catkey and is a top level collection
  let(:druid_object) { DruidTools::PurlDruid.new('bb050dj6667', purl_fixture_path) }
  let(:n) { 3 } # number of druids on the fixture document_cache

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
      expect(purl_finder.path_to_deletes_dir).to match(/\.deletes/)
      expect(purl_finder.path_to_deletes_dir.class).to eq(String)
    end

    it 'returns the default output finder file location' do
      expect(purl_finder.default_output_file).to eq(File.join(Rails.root, 'log/purl_finder'))
    end
  end

  describe('Saving/finding') do
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
        expect(UpdatingLogger).to receive(:error).once
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
        Purl.save_from_public_xml(test_purl_dest_dir) # add the purl to the database
        expect(Purl.all.count).to eq(num_purl_fixtures_in_database + 1) # now we have one more record in the database
        purl = Purl.find_by_druid('druid:bb050dj6667')
        expect(purl.druid).to eq('druid:bb050dj6667') # confirm the druid
        expect(purl.deleted_at?).to be_falsey # it is not deleted

        delete_dir(test_purl_dest_dir) # remove its files
        delete_file = druid_object.creates_delete_record.first # create its delete record
        expect(UpdatingLogger).to receive(:info).with(/deleting/).once
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

    describe('Finding changed files on the purl mount') do
      before :each do
        Dir.glob(File.join(purl_fixture_path, '**', '*')).each do |f|
          FileUtils.touch f, mtime: (Time.zone.now - 2.minutes).to_i
        end
      end

      after :each do
        # Clear the temp file and purl back out
        delete_file(empty_file)
        delete_dir(test_purl_dest_dir)
      end

      it 'finds public files correctly using time constraints' do
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
        finder_file_test(mins_ago: nil, expected_num_files_found: n)

        # # Make sure we filter only on files we want
        FileUtils.touch(empty_file) # add in a fake files who change should not trigger
        # # Since this file does not matter, it should not be found
        finder_file_test(mins_ago: nil, expected_num_files_found: n)

        # add another purl
        FileUtils.cp_r test_purl_source_dir, test_purl_dest_dir

        # # We now have a new file
        finder_file_test(mins_ago: nil, expected_num_files_found: n + 1)

        # Clear the temp file and purl back out
        delete_file(empty_file)
        delete_dir(test_purl_dest_dir)

        # back to n files
        finder_file_test(mins_ago: nil, expected_num_files_found: n)
      end
    end
  end
end
