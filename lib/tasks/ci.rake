require 'jettywrapper' unless Rails.env.production? 
require 'rest_client'

desc "Run continuous integration suite (assuming jetty is not yet started)"
task :ci do
  unless Rails.env.test?  
    system("bundle exec rake ci RAILS_ENV=test")
  else
    system("bundle exec rake db:migrate RAILS_ENV=test")  
    Jettywrapper.wrap(Jettywrapper.load_config) do
      Rake::Task["dorfetcher:refresh_fixtures"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:fixtures:load"].invoke
      Rake::Task["db:seed"].invoke      
      system('bundle exec rspec spec --color')
    end
  end
end

desc "Assuming jetty is already running - then migrate, reload all fixtures and run rspec"
task :local_ci do  
  Rails.env='test'
  ENV['RAILS_ENV']='test'
  Rake::Task["dorfetcher:refresh_fixtures"].invoke
  Rake::Task["db:migrate"].invoke
  Rake::Task["db:fixtures:load"].invoke
  Rake::Task["db:seed"].invoke
  system('bundle exec rspec spec --color')
end

namespace :dorfetcher do
  
  desc "Copy configuration files"
  task :config do
    Rake::Task["jetty:stop"].invoke
    system('rm -fr jetty/solr/dev/data/index')
    system('rm -fr jetty/solr/test/data/index')
    cp("#{Rails.root}/config/database.yml.example", "#{Rails.root}/config/database.yml") unless File.exists?("#{Rails.root}/config/database.yml")
    cp("#{Rails.root}/config/solr.yml.example", "#{Rails.root}/config/solr.yml") unless File.exists?("#{Rails.root}/config/solr.yml")
    cp("#{Rails.root}/config/schema.xml", "#{Rails.root}/jetty/solr/dev/conf/schema.xml")
    cp("#{Rails.root}/config/schema.xml", "#{Rails.root}/jetty/solr/test/conf/schema.xml")
    cp("#{Rails.root}/config/solrconfig.xml", "#{Rails.root}/jetty/solr/dev/conf/solrconfig.xml")
    cp("#{Rails.root}/config/solrconfig.xml", "#{Rails.root}/jetty/solr/test/conf/solrconfig.xml")
  end  
  
  desc "Delete and index all fixtures in solr"
  task :refresh_fixtures do
    unless Rails.env.production? || Rails.env.staging? || DorFetcherService::Application.config.solr_url.include?('8080')
      Rake::Task["dorfetcher:delete_records_in_solr"].invoke
      Rake::Task["dorfetcher:index_fixtures"].invoke
    else
      puts "Refusing to delete since we're running under the #{Rails.env} environment or port 8080. You know, for safety."      
    end
  end
  
  desc "Index all fixtures into solr"
  task :index_fixtures do
    add_docs = []
    Dir.glob("#{Rails.root}/spec/fixtures/*.xml") do |file|
      add_docs << File.read(file)
    end
    puts "Adding #{add_docs.count} documents to #{DorFetcherService::Application.config.solr_url}"
    RestClient.post "#{DorFetcherService::Application.config.solr_url}/update?commit=true", "<update><add>#{add_docs.join(" ")}</add></update>", :content_type => "text/xml"
  end
  
  desc "Clean up saved items - remove any saved items which reference items/solr documents that do not exist"
  task :cleanup_saved_items => :environment do |t, args|
    SavedItem.all.each { |saved_item| saved_item.destroy if saved_item.solr_document.nil? }
  end

  desc "Delete all records in solr"
  task :delete_records_in_solr do
    unless Rails.env.production? || Rails.env.staging? || DorFetcherService::Application.config.solr_url.include?('8080')
      puts "Deleting all solr documents from #{DorFetcherService::Application.config.solr_url}"
      puts DorFetcherService::Application.config.solr_url 
      RestClient.post "#{DorFetcherService::Application.config.solr_url}/update?commit=true", "<delete><query>*:*</query></delete>" , :content_type => "text/xml"
    else
      puts "Refusing to delete since we're running under the #{Rails.env} environment or port 8080. You know, for safety."
    end
  end
end