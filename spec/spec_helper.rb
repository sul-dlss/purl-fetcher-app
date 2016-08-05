require 'coveralls'
Coveralls.wear!('rails')

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    # be_bigger_than(2).and_smaller_than(4).description
    #   # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #   # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on a real object.
    # This is generally recommended, and will default to `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

end

def line_count(output_file)
  File.open(output_file,"r").readlines.size
end

def finder_file_test(params={})
  delete_file(purl_finder.default_output_file) # remove the default finder output location to be sure it gets created again
  expect(File.exist?(purl_finder.default_output_file)).to be_falsey
  purl_finder.find_files(mins_ago: params[:mins_ago]) # find files and store in default output file
  expect(File.exist?(purl_finder.default_output_file)).to be_truthy
  expect(line_count(purl_finder.default_output_file)).to eq(params[:expected_num_files_found])
end

def num_purl_fixtures_in_database
  4 # Purl.all.count # this is useful to know for testing expectations that will increase this number during the test
end

def fixture_druids_in_database
  ["druid:bb1111cc2222", "druid:cc1111dd2222", "druid:dd1111ee2222", "druid:ee1111ff2222"] # Purl.all.map(&:druid)
end

def purl_fixture_path
  File.join(Rails.root,'spec','purl-test-fixtures','document_cache')
end

# This is a path that hold a copy of a sample purl path that is moved into the testing folder to facilitate testing, it is then removed
def temp_purl_fixture_path
  File.join(purl_fixture_path,'..','temp')
end

def test_purl_source_dir
  DruidTools::PurlDruid.new('bb050dj6667', temp_purl_fixture_path).path
end

def test_purl_dest_dir
 DruidTools::PurlDruid.new('bb050dj6667', purl_fixture_path).path
end

def empty_file
 File.join(sample_doc_path, 'my_updates_do_not_count')
end

def sample_doc_path
  DruidTools::PurlDruid.new('bb050dj7711', purl_fixture_path).path
end

def remove_delete_records(dir_path, records)
  records.each { |r| delete_file(Pathname(File.join(dir_path,r))) }
end

def remove_purl_file(dir_path, purl_path)
  delete_file(Pathname(File.join(dir_path,purl_path)))
end

def delete_file(file_path)
  FileUtils.rm(file_path) if File.exist?(file_path)
end

def delete_dir(path)
  FileUtils.rm_r(path) if File.directory?(path)
end

def all_time
  {first_modified: Time.zone.at(0).iso8601, last_modified: Time.zone.at(9_999_999_999).iso8601}
end
