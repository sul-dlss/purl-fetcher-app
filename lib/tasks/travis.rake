require 'jettywrapper' unless Rails.env.production? || Rails.env.development?
require 'rest_client'

desc 'Run the tests on Travis'
task :travis_spec do
  Rake::Task['rspec'].invoke
end
