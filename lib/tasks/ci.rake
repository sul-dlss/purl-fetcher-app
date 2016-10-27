begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  desc 'rspec unavailable'
  task :spec do
    abort 'rspec not installed'
  end
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.fail_on_error = true
  end
rescue LoadError
  desc 'rubocop unavailable'
  task :rubocop do
    abort 'Unable to load RuboCop.'
  end
end
