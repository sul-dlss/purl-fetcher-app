require 'jettywrapper' unless Rails.env.production? || Rails.env.development?
require 'rest_client'

desc 'Run continuous integration suite (tests, coverage, rubocop)'
task :ci do
   system('RAILS_ENV=test rake db:test:prepare')
   Rake::Task['rspec'].invoke
   Rake::Task['rubocop'].invoke
end

desc 'Rebuild vcr cassettes and run tests (assuming jetty is not yet started)'
task :rebuild_cassettes do
  unless Rails.env.test?
    system('bundle exec rake rebuild_cassettes RAILS_ENV=test')
  else
    system('rm -fr spec/vcr_cassettes')
    Jettywrapper.wrap(Jettywrapper.load_config) do
      Rake::Task['purlfetcher:refresh_fixtures'].invoke
      Rake::Task['rspec'].invoke
    end
    system('rm spec/vcr_cassettes/doc_submit_fails.yml') # these two cassettes get created when you run the tests, but you don't want them (see spec/features/indexer_spec.rb:197)
    system('rm spec/vcr_cassettes/failed_solr_commit.yml')
  end
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

namespace :purlfetcher do
  desc 'Copy all configuration files'
  task :config do
    Rake::Task['jetty:stop'].invoke
    system('rm -fr jetty/solr/dev/data/index jetty/solr/test/data/index')
    cp("#{Rails.root}/config/database.yml.example", "#{Rails.root}/config/database.yml", :verbose => true)
    %w(schema solrconfig).each do |f|
      cp("#{Rails.root}/config/#{f}.xml", "#{Rails.root}/jetty/solr/dev/conf/#{f}.xml", :verbose => true)
      cp("#{Rails.root}/config/#{f}.xml", "#{Rails.root}/jetty/solr/test/conf/#{f}.xml", :verbose => true)
    end
  end

  desc 'Delete and index all fixtures in solr'
  task :refresh_fixtures do
    unless Rails.env.production? || Rails.env.staging? || !PurlFetcher::Application.config.solr_url.include?('8983')
      WebMock.disable! if Rails.env.test? # Webmock will block all http connections by default under test, allow us to reload the fixtures
      Rake::Task['purlfetcher:delete_records_in_solr'].invoke
      Rake::Task['purlfetcher:index_fixtures'].invoke
      WebMock.enable! if Rails.env.test?  # Bring webmock back online
    else
      puts "Refusing to delete since we're running under the #{Rails.env} environment or not on port 8983. You know, for safety."
    end
  end

  desc 'Index all fixtures into solr'
  task :index_fixtures do
    add_docs = Dir.glob("#{Rails.root}/spec/fixtures/*.xml").map { |file| File.read(file) }
    puts "Adding #{add_docs.count} documents to #{PurlFetcher::Application.config.solr_url}"
    RestClient.post "#{PurlFetcher::Application.config.solr_url}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => 'text/xml'
  end

  desc 'Delete all records in solr'
  task :delete_records_in_solr do
    unless Rails.env.production? || Rails.env.staging? || !PurlFetcher::Application.config.solr_url.include?('8983')
      puts "Deleting all solr documents from #{PurlFetcher::Application.config.solr_url}"
      puts PurlFetcher::Application.config.solr_url
      RestClient.post "#{PurlFetcher::Application.config.solr_url}/update?commit=true", '<delete><query>*:*</query></delete>', :content_type => 'text/xml'
    else
      puts "Refusing to delete since we're running under the #{Rails.env} environment or not on port 8983. You know, for safety."
    end
  end
end
