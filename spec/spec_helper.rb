require 'simplecov'
SimpleCov.start 'rails'
require 'factory_bot_rails'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
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
  # rspec-expectations config goes here. You can use an alternate
   # assertion/expectation library such as wrong or the stdlib/minitest
   # assertions if you prefer.
   config.expect_with :rspec do |expectations|
     # This option will default to `true` in RSpec 4. It makes the `description`
     # and `failure_message` of custom matchers include text for helper methods
     # defined using `chain`, e.g.:
     #     be_bigger_than(2).and_smaller_than(4).description
     #     # => "be bigger than 2 and smaller than 4"
     # ...rather than:
     #     # => "be bigger than 2"
     expectations.include_chain_clauses_in_custom_matcher_descriptions = true
   end

   # rspec-mocks config goes here. You can use an alternate test double
   # library (such as bogus or mocha) by changing the `mock_with` option here.
   config.mock_with :rspec do |mocks|
     # Prevents you from mocking or stubbing a method that does not exist on
     # a real object. This is generally recommended, and will default to
     # `true` in RSpec 4.
     mocks.verify_partial_doubles = true
   end

   # Allow mocking/stubbing methods in view-specs only.
   config.before(:each, type: :view) do
     config.mock_with :rspec do |mocks|
       mocks.verify_partial_doubles = false
     end
   end

   config.after(:each, type: :view) do
     config.mock_with :rspec do |mocks|
       mocks.verify_partial_doubles = true
     end
   end

   # The settings below are suggested to provide a good initial experience
   # with RSpec, but feel free to customize to your heart's content.

   # These two settings work together to allow you to limit a spec run
   # to individual examples or groups you care about by tagging them with
   # `:focus` metadata. When nothing is tagged with `:focus`, all examples
   # get run.
   config.filter_run :focus
   config.run_all_when_everything_filtered = true

   # Limits the available syntax to the non-monkey patched syntax that is
   # recommended. For more details, see:
   #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
   #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
   #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching
   #  config.disable_monkey_patching!

   # Many RSpec users commonly either run the entire suite or an individual
   # file, and it's useful to allow more verbose output when running an
   # individual spec file.
   if config.files_to_run.one?
     # Use the documentation formatter for detailed output,
     # unless a formatter has already been configured
     # (e.g. via a command-line flag).
     config.default_formatter = 'doc'
   end

   # Print the 10 slowest examples and example groups at the
   # end of the spec run, to help surface which specs are running
   # particularly slow.
   config.profile_examples = 10

   # Run specs in random order to surface order dependencies. If you find an
   # order dependency and want to debug it, you can fix the order by providing
   # the seed, which is printed after each run.
   #     --seed 1234
   config.order = :random

   # Seed global randomization in this process using the `--seed` CLI option.
   # Setting this allows you to use `--seed` to deterministically reproduce
   # test failures related to randomization by passing the same `--seed` value
   # as the one that triggered the failure.
  #  Kernel.srand config.seed
end

def line_count(output_file)
  File.open(output_file,"r").readlines.size
end

def finder_file_test(params={})
  expect(purl_finder.find_files(mins_ago: params[:mins_ago]).count).to eq params[:expected_num_files_found]
end

def num_purl_fixtures_in_database
  8 # Purl.all.count # this is useful to know for testing expectations that will increase this number during the test
end

def fixture_druids_in_database
  ["druid:bb111cc2222", "druid:cc111dd2222", "druid:dd111ee2222", "druid:ee111ff2222", "druid:ff111gg2222", 'druid:aa111bb2222'].sort # Purl.all.map(&:druid)
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
