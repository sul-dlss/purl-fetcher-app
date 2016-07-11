require 'jettywrapper' unless Rails.env.production? || Rails.env.development?
require 'rest_client'

desc 'Run continuous integration suite (assuming jetty is not yet started)'
task :ci do
  Rake::Task['rubocop'].invoke
  unless Rails.env.test?
    system('bundle exec rake ci RAILS_ENV=test')
  else
    system('bundle exec rake db:migrate RAILS_ENV=test')
    Jettywrapper.wrap(Jettywrapper.load_config) do
      Rake::Task['purlfetcher:refresh_fixtures'].invoke
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:fixtures:load'].invoke
      Rake::Task['db:seed'].invoke
      system('bundle exec rspec spec --color')
    end
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

desc 'Assuming jetty is already running - then migrate, reload all fixtures and run rspec'
task :local_ci do
  unless Rails.env.test?
    system('bundle exec rake local_ci RAILS_ENV=test')
  else
    Rake::Task['purlfetcher:refresh_fixtures'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:fixtures:load'].invoke
    Rake::Task['db:seed'].invoke
    system('bundle exec rspec spec --color')
  end
end

namespace :purlfetcher do
  desc 'Copy just shared yml files'
  task :config_yml do
    %w(database solr secrets).each do |f|
      next if File.exist? "#{Rails.root}/config/#{f}.yml"
      cp("#{Rails.root}/config/#{f}.yml.example", "#{Rails.root}/config/#{f}.yml", :verbose => true)
    end
  end

  desc 'Copy all configuration files'
  task :config do
    Rake::Task['jetty:stop'].invoke
    Rake::Task['purlfetcher:config_yml'].invoke
    system('rm -fr jetty/solr/dev/data/index jetty/solr/test/data/index')
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

  desc 'Clean up saved items - remove any saved items which reference items/solr documents that do not exist'
  task :cleanup_saved_items => :environment do |t, args|
    SavedItem.all.each { |saved_item| saved_item.destroy if saved_item.solr_document.nil? }
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
