require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)




module DorFetcherService
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    #Add in files in lib/ such as the fetcher module
    config.autoload_paths << Rails.root.join('lib')
    
    load_yaml_config = lambda { |yaml_file|
      full_path = File.expand_path(File.join(File.dirname(__FILE__), yaml_file))
      yaml      = YAML.load(File.read full_path)
      return yaml[Rails.env]
    }
    
    config.solr_url=load_yaml_config.call('solr.yml')['url']
    config.solr_terms = load_yaml_config.call('solr_terms.yml')
    
    
  end
  
  
end

#Convienence constant for SOLR_URL and SOLR
Solr_URL = DorFetcherService::Application.config.solr_url
Solr= RSolr.connect :url => Solr_URL

#Convience constants for Solr Fields
#solr_field_yaml = DorFetcherService::Application.config.solr_terms
ID_Field = DorFetcherService::Application.config.solr_terms['id_field']
Type_Field = DorFetcherService::Application.config.solr_terms['fedora_type_field'] 
Last_Changed_Field = DorFetcherService::Application.config.solr_terms['last_changed']
Fedora_Prefix = DorFetcherService::Application.config.solr_terms['fedora_prefix']
Druid_Prefix = DorFetcherService::Application.config.solr_terms['druid_prefix']
Fedora_Types = {:collection => DorFetcherService::Application.config.solr_terms['collection_type'], :apo => DorFetcherService::Application.config.solr_terms['apo_type']}
Controller_Types = {:collection => DorFetcherService::Application.config.solr_terms['collection_field'], :apo=> DorFetcherService::Application.config.solr_terms['apo_field'], :tag=> DorFetcherService::Application.config.solr_terms['tag_field']}


#solr_fields = {:apo_field => apo_field, :collection_field => collection_field}