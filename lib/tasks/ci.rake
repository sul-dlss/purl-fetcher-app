require 'jettywrapper' unless Rails.env.production? || Rails.env.development?
require 'rest_client'

desc 'Run continuous integration suite (assuming jetty is not yet started)'
task :ci do
  unless Rails.env.test?
    system('bundle exec rake ci RAILS_ENV=test')
  else
    system('bundle exec rake db:migrate RAILS_ENV=test')
    Jettywrapper.wrap(Jettywrapper.load_config) do
      Rake::Task['dorfetcher:refresh_fixtures'].invoke
      Rake::Task['db:migrate'].invoke
      Rake::Task['db:fixtures:load'].invoke
      Rake::Task['db:seed'].invoke
      system('bundle exec rspec spec --color')
    end
  end
end

desc 'Assuming jetty is already running - then migrate, reload all fixtures and run rspec'
task :local_ci do
  unless Rails.env.test?
    system('bundle exec rake local_ci RAILS_ENV=test')
  else
    Rake::Task['dorfetcher:refresh_fixtures'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:fixtures:load'].invoke
    Rake::Task['db:seed'].invoke
    system('bundle exec rspec spec --color')
  end
end

namespace :dorfetcher do
  desc 'Copy just shared yml files'
  task :config_yml do
    config_files = %w{database.yml solr.yml secrets.yml}
    config_files.each {|config_file| cp("#{Rails.root}/config/#{config_file}.example", "#{Rails.root}/config/#{config_file}") unless File.exists?("#{Rails.root}/config/#{config_file}.yml")}
  end

  desc 'Copy all configuration files'
  task :config do
    Rake::Task['jetty:stop'].invoke
    Rake::Task['dorfetcher:config_yml'].invoke
    system('rm -fr jetty/solr/dev/data/index')
    system('rm -fr jetty/solr/test/data/index')
    solr_files = %w{schema.xml solrconfig.xml}
    solr_files.each do |solr_file|
      cp("#{Rails.root}/config/#{solr_file}", "#{Rails.root}/jetty/solr/dev/conf/#{solr_file}")
      cp("#{Rails.root}/config/#{solr_file}", "#{Rails.root}/jetty/solr/test/conf/#{solr_file}")
    end
  end

  desc 'Delete and index all fixtures in solr'
  task :refresh_fixtures do
    unless Rails.env.production? || Rails.env.staging? || !DorFetcherService::Application.config.solr_url.include?('8983')
      WebMock.disable! if Rails.env.test? # Webmock will block all http connections by default under test, allow us to reload the fixtures
      Rake::Task['dorfetcher:delete_records_in_solr'].invoke
      Rake::Task['dorfetcher:index_fixtures'].invoke
      WebMock.enable! if Rails.env.test?  # Bring webmock back online
    else
      puts "Refusing to delete since we're running under the #{Rails.env} environment or not on port 8983. You know, for safety."
    end
  end

  desc 'Index all fixtures into solr'
  task :index_fixtures do
    add_docs = []
    Dir.glob("#{Rails.root}/spec/fixtures/*.xml") do |file|
      add_docs << File.read(file)
    end
    puts "Adding #{add_docs.count} documents to #{DorFetcherService::Application.config.solr_url}"
    RestClient.post "#{DorFetcherService::Application.config.solr_url}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => 'text/xml'
  end

  desc 'Clean up saved items - remove any saved items which reference items/solr documents that do not exist'
  task :cleanup_saved_items => :environment do |t, args|
    SavedItem.all.each { |saved_item| saved_item.destroy if saved_item.solr_document.nil? }
  end

  desc 'Delete all records in solr'
  task :delete_records_in_solr do
    unless Rails.env.production? || Rails.env.staging? || !DorFetcherService::Application.config.solr_url.include?('8983')
      puts "Deleting all solr documents from #{DorFetcherService::Application.config.solr_url}"
      puts DorFetcherService::Application.config.solr_url
      RestClient.post "#{DorFetcherService::Application.config.solr_url}/update?commit=true", '<delete><query>*:*</query></delete>', :content_type => 'text/xml'
    else
      puts "Refusing to delete since we're running under the #{Rails.env} environment or not on port 8983. You know, for safety."
    end
  end
end
