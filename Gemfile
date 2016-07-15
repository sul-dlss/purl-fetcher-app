source 'https://rubygems.org'

gem 'rails', '>=4.1.6'
gem 'rsolr', '>=1.0.10'

gem 'rest-client'
gem 'parallel'
gem 'stanford-mods'
gem 'retries'
gem 'druid-tools'
gem 'whenever'

# Squash
gem 'squash_ruby', :require => 'squash/ruby'
gem 'squash_rails', :require => 'squash/rails'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.3'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'turbolinks'

gem 'is_it_working-cbeer'
gem 'about_page'

group :test do
  gem 'sqlite3'
  gem 'yard'
  gem 'vcr'
  gem 'webmock'
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara'
  gem 'coveralls', require: false
end

group :deployment do
  gem 'dlss-capistrano'
end

group :staging, :production, :development do
  gem 'mysql'
  gem 'mysql2'
end

group :development, :test do
  gem 'jettywrapper'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'launchy'
  gem 'thin'
  gem 'dlss_cops'
end
