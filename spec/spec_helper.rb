require 'vcr'
require 'coveralls'
Coveralls.wear!('rails')

# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause this
# file to always be loaded, without a need to explicitly require it in any files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
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
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
=begin
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Limits the available syntax to the non-monkey patched syntax that is recommended.
  # For more details, see:
  #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
  #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching
  config.disable_monkey_patching!

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
  Kernel.srand config.seed
=end
end



VCR.configure do |c|
  c.cassette_library_dir = 'spec/vcr_cassettes'
  c.hook_into :webmock
end

#This only checks to see if the druids you are looking for are present
#Other druids may be present as well, so I suggest you also test for total number returned
def result_should_contain_druids(druids, response)
  response.each do |r|
    expect(druids.include?(r['druid'])).to be true
  end
end

def result_should_not_contain_druids(druids, response)
  response.each do |r|
    expect(druids.include?(r['druid'])).to be false
  end
end

#Due to VCR we need to have a fixed last_modified date, since time now will vary
#You'll have one time now from when you recorded and another from when travis_ci or such runs the tests
def add_late_end_date(params)
  #Warning: Not Y10K Compliant!  
  return params[:last_modified] = :last_modified => '9999-12-31T23:59:59Z'
end

def just_late_end_date
  return add_late_end_date({})
end

def add_params_to_url(url, params)
  count = 0 
  params.each do |key,value|
    if count == 0 
      url << "?"
    else
      url << "&"
    end
    count += 1
    url << "#{key.to_s}=#{value}"
  end
  return url
end

def all_counts_keys
  #do not include counts_key, it is the parent
  return [collections_key, items_key, apos_key, total_count_key]
end

def collections_key
  return 'collections'
end

def items_key
  return 'items'
end

def apos_key
  return 'adminpolicies'
end

def counts_key
  return 'counts'
end

def total_count_key
  return 'total_count'
end

#Automatically gets total counts, don't need to add it
def verify_counts_section(response, counts)
  total_count = 0 
  nil_keys = all_counts_keys-[total_count_key]
  counts.each do |key,value|
    
    #Make the count is what we expect it to be
    expect(response[counts_key][key]).to eq(value)
    
    #Go back to the JSON section that lists all the druids and make sure its size equals the value listed in count
    expect(response[key].size).to eq(value)
    
    total_count += value
    
    #This key was present, so we don't expect it to be nil
    nil_keys -= [key]  
    
  end
  #If the tester didn't specify total count above, check it
  expect(total_count).to eq(response[counts_key][total_count_key]) if counts[total_count_key = nil]
  
  #Make sure the keys we expect to be nil aren't in the counts section
  nil_keys.each do |key|
    expect(response[counts_key][key]).to be nil
  end
  
end

def just_count_param
  return {"rows"=> 0}
end

def last_mod_test_date_collections
  return '2013-12-31T23:59:59Z'
end

def first_mod_test_date_collections
  return '2014-1-1T00:00:00Z'
end

