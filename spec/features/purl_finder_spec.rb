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
