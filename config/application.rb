require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'logger'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

VERSION = File.read('VERSION')

module PurlFetcher
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

    # Add in files in lib/
    config.autoload_paths << Rails.root.join('lib')

    config.version = VERSION # read from VERSION file at base of website
    config.app_name = 'PurlFetcher'

    load_yaml_config = lambda { |yaml_file|
      full_path = File.expand_path(File.join(File.dirname(__FILE__), yaml_file))
      yaml_erb  = ERB.new(IO.read(full_path)).result(binding)
      yaml      = YAML.load(yaml_erb)
      return yaml[Rails.env]
    }

    begin
      config.solr_url = load_yaml_config.call('solr.yml')['url']
    rescue
      puts 'WARNING: config/solr.yml config not found'
    end

    begin
      config.solr_indexing = load_yaml_config.call('solr_indexing.yml')
    rescue
      puts 'WARNING: config/solr_indexing.yml config not found'
    end

    begin
      config.time_zone = 'UTC'
    rescue
      puts 'WARNING: could not configure time zone to utc'
    end
  end
end

IndexingLogger = Logger.new(PurlFetcher::Application.config.solr_indexing['filename_indexing_log'])
