require 'vcr'
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

# To record new cassettes:
#   remove old ones; update index or configure new source; uncomment default_cassette_options; and run tests
VCR.configure do |c|
  # c.default_cassette_options = { :record => :new_episodes }
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
end

def line_count(output_file)
  File.open(output_file,"r").readlines.size
end

def finder_file_test(params={})
  FileUtils.rm(indexer.default_output_file) if File.exist?(indexer.default_output_file) # remove the default finder output location to be sure it gets created again
  expect(File.exist?(indexer.default_output_file)).to be_falsey
  indexer.find_files(mins_ago: params[:mins_ago]) # find files and store in default output file
  expect(File.exist?(indexer.default_output_file)).to be_truthy
  expect(line_count(indexer.default_output_file)).to eq(params[:expected_num_files_found])
end

def purl_fixture_path
  File.join(Rails.root,'spec','purl-test-fixtures','document_cache')
end

# Remove records from the deletes dir to avoid having them picked up by other tests
#
# @dir_path [String] The path to the directory
# @params records [Array] An array of strings of the records you want to be deleted
#
# @return [void]
def remove_delete_records(dir_path, records)
  records.each { |r| delete_file(Pathname(File.join(dir_path,r))) }
end

def remove_purl_file(dir_path, purl_path)
  delete_file(Pathname(File.join(dir_path,purl_path)))
end

def delete_file(file_path)
  FileUtils.rm(file_path) if File.exist? file_path
end

# Generate a number of stub solr paths
def generate_fake_paths(number_of_objects)
  (0..number_of_objects).to_a.map { |i| "/purl/foo/bar/#{i}" }
end
