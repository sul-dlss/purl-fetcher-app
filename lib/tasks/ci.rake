namespace :purl_fetcher do
  desc 'Run the apps specs'
  task :spec do
    require 'rspec/core/rake_task'
    RSpec::Core::RakeTask.new(:rspec)
    Rake::Task['rspec'].invoke
  rescue LoadError
    desc 'rspec unavailable'
    abort 'rspec not installed'
  end
end

desc 'Run continuous integration suite (tests, coverage, rubocop)'
task :ci do
  system('RAILS_ENV=test rake db:migrate')
  system('RAILS_ENV=test rake db:test:prepare')
  Rake::Task['purl_fetcher:spec'].invoke
  Rake::Task['rubocop'].invoke
end

desc 'Run rubocop on ruby files'
task :rubocop do
  if Rails.env.test? || Rails.env.development?
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new
    rescue LoadError
      puts 'Unable to load RuboCop.'
    end
  end
end
