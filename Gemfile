source 'https://rubygems.org'

gem 'rails', '>=4.1.6'
gem 'rsolr', '>=1.0.10'

gem 'rest-client'
gem 'parallel'
gem 'stanford-mods'
gem 'retries'
gem 'druid-tools'
gem 'whenever'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'is_it_working-cbeer'
gem 'about_page'

group :test do
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

group :development, :test do
  gem 'jettywrapper'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'launchy'
  gem 'thin'
  gem 'dlss_cops'
end
