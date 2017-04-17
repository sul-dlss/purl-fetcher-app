source 'https://rubygems.org'

gem 'rails', '~> 5'


# http://stackoverflow.com/questions/35893584/nomethoderror-undefined-method-last-comment-after-upgrading-to-rake-11
# same error in travis build with rake v12.0.0, so I chose to pin rake back
gem 'rake', '~> 11.3.0'

gem 'druid-tools'
gem 'whenever', :require => false
gem 'kaminari' # for pagination

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

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
