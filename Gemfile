source 'https://rubygems.org'

gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
gem 'rake' # for various admin tasks

gem 'druid-tools'
gem 'whenever', :require => false
gem 'kaminari' # for pagination

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

gem 'okcomputer' # for monitoring
gem 'honeybadger', '~> 2.0'
gem 'listen' # for PurlListener
gem 'config'

group :test do
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara'
  gem 'coveralls', require: false
  gem 'rails-controller-testing'
end

group :production do
  gem 'mysql2'
end

group :deployment do
  gem 'dlss-capistrano'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
end

group :development, :test do
  gem 'factory_girl_rails'
  gem 'dlss_cops'
  gem 'sqlite3'
  gem 'yard'
end
