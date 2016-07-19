# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:rspec)
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # ignore in non-test environments
end

Rails.application.load_tasks
