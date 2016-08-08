source 'https://rubygems.org'

gem 'rails', '>=4.1.6'

gem 'rest-client'
gem 'stanford-mods'
gem 'retries'
gem 'druid-tools'
gem 'whenever', :require => false

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'is_it_working-cbeer'
gem 'about_page'
gem 'honeybadger', '~> 2.0'

group :test do
  gem 'yard'
  gem 'webmock'
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara'
  gem 'coveralls', require: false
end

group :staging, :production do
  gem 'mysql2'
end

group :deployment do
  gem 'dlss-capistrano'
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-rvm'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
end

group :development, :test do
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'launchy'
  gem 'thin'
  gem 'dlss_cops'
  gem 'sqlite3'
end
