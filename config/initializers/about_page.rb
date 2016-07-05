AboutPage.configure do |config|
  config.app           = { :name => PurlFetcher::Application.config.app_name, :version => PurlFetcher::Application.config.version }
  config.environment   = AboutPage::Environment.new({
    'Ruby' => /^(RUBY|GEM_|rvm)/, # This defines a "Ruby" subsection containing
    # environment variables whose names match the RegExp
  })
  config.request = AboutPage::RequestEnvironment.new({
    'HTTP Server' => /^(SERVER_|POW_)/ # This defines an "HTTP Server" subsection containing
    # request variables whose names match the RegExp
  })
  config.dependencies = AboutPage::Dependencies.new
end
