source 'https://rubygems.org'

gem 'rails', '~> 4.2', '>= 4.2.7.1'
gem 'rake' # for various admin tasks

gem 'druid-tools'
gem 'whenever', :require => false
gem 'kaminari' # for pagination

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'is_it_working-cbeer'
gem 'about_page'
gem 'honeybadger', '~> 2.0'
gem 'listen' # for PurlListener
gem 'config'

group :test do
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara'
  gem 'coveralls', require: false
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
  gem 'dlss_cops'
  gem 'sqlite3'
  gem 'yard'
end
