source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.2'
gem 'rake', '~> 12'

# Use Puma as the app server
gem 'puma', '~> 3.7'

gem 'druid-tools'
gem 'whenever', :require => false
gem 'kaminari' # for pagination

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

gem 'okcomputer' # for monitoring
gem 'honeybadger', '~> 3.0'

gem 'listen', '>= 3.0.5', '< 3.2' # used by PurlListener
gem 'config'

group :test do
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara'
  gem 'coveralls', require: false
  gem 'rails-controller-testing'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
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
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'sqlite3'
  gem 'yard'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
