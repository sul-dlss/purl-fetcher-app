require_relative 'boot'

require 'rails/all'
require 'logger'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PurlFetcher
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Add in files in lib/
    config.eager_load_paths << Rails.root.join('lib')

    config.version = File.read('VERSION') # read from VERSION file at base of website
    config.app_name = 'PurlFetcher'
  end
end

UpdatingLogger = Logger.new(Settings.FILENAME_UPDATING_LOG)
UpdatingLogger.level = Logger::INFO
