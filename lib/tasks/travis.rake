require 'jettywrapper' unless Rails.env.production? or Rails.env.development?
require 'rest_client'

desc "Set up default database.yml for Travis and run the tests."
task :travis_spec do
  `cp config/database.yml.example config/database.yml`
  `cp config/solr.yml.example config/solr.yml`
  Rake::Task['rspec'].invoke
end