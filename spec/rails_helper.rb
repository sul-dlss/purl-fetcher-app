# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'net/http'
require 'capybara/rspec'
require 'capybara/rails'
require 'json'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/test/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.include Capybara::DSL
  
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
end

class FetcherTester
  include Fetcher
end

class FixtureData
  
  
  @@apo_druids = ['druid:qv648vd4392', 'druid:vb546ms7107'] 
  
  #Collections
  @@stafford_collection_druids = ['druid:yg867hg1375']
  @@revs_collection_druids = ['druid:nt028fd5773', 'druid:wy149zp6932', 'druid:yt502zj0924']
  @@collection_druids =  @@stafford_collection_druids + @@revs_collection_druids
  
  #Items
  @@stafford_items_druids = ['druid:jf275fd6276', 'druid:nz353cp1092', 'druid:tc552kq0798', 'druid:th998nk0722','druid:ww689vs6534']
  @@revs_items_druids = ['druid:bb001zc5754', 'druid:bb004bn8654', 'druid:bb013sq9803', 'druid:bb014bd3784', 'druid:bb023nj3137','druid:bb027yn4436','druid:bb048rn5648', 'druid:bb113tm9924']
  @@items_druids = @@stafford_items_druids + @@revs_items_druids
  
  def all_druids
    return @@apo_druids + @@collection_druids + @@items_druids
  end
   
  def all_collection_druids
    return @@collection_druids
  end
  
  def stafford_collections_druids
    return @@stafford_collection_druids
  end
  
  def revs_collections_druids
    @@revs_collection_druids
  end
   
  def apo_druids
    return @@apo_druids
  end
  
  def revs_items_druids
     return @@revs_items_druids
  end
  
  def stafford_items_druids
    return @@stafford_items_druids 
  end
  
  def all_items_druids
    return @@items_druids = @@stafford_items_druids
  end
   
  def get_response(url)
    return Net::HTTP.get_response(URI.parse(url))
  end
  
  def get_response_body(url)
    return JSON.parse(get_response(url).body)
  end

end