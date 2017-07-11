begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  puts 'Unable to load RuboCop.'
end

desc 'Run continuous integration suite (tests, coverage, rubocop)'
task :ci do
  system('RAILS_ENV=test rake db:migrate')
  system('RAILS_ENV=test rake db:test:prepare')
  Rake::Task['spec'].invoke
  Rake::Task['rubocop'].invoke
end
