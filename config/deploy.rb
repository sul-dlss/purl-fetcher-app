set :application, 'purl-fetcher'
set :repo_url, 'https://github.com/sul-dlss/purl-fetcher.git'
set :user, 'lyberadmin'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

set :home_directory, "/opt/app/#{fetch(:user)}"
set :deploy_to, "#{fetch(:home_directory)}/#{fetch(:application)}"

# Whenever
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

# Default value for :linked_files is []
set :linked_files, %w{config/solr.yml config/secrets.yml config/database.yml config/honeybadger.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for keep_releases is 5
set :keep_releases, 5

# server uses standardized suffix
server "purl-fetcher-#{fetch(:stage)}.stanford.edu", user: fetch(:user), roles: %w{web db app}

# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, "#{fetch(:stage)}"
