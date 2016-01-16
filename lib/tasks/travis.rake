require 'jettywrapper' unless Rails.env.production? || Rails.env.development?
require 'rest_client'

desc 'Set up default .yml config files for Travis and run the tests.'
task :travis_spec do
  Rake::Task['dorfetcher:config_yml'].invoke
  Rake::Task['rspec'].invoke
end
