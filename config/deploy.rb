set :application, 'purl-fetcher'
set :repo_url, 'https://github.com/sul-dlss/purl-fetcher.git'

# Default branch is :master
set :branch, 'master'

set :deploy_to, "/opt/app/lyberadmin/purl-fetcher"

# Whenever
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

# Default value for :linked_files is []
set :linked_files, %w{config/secrets.yml config/database.yml config/honeybadger.yml config/newrelic.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log run tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for keep_releases is 5
set :keep_releases, 5

# honeybadger_env otherwise defaults to rails_env
set :honeybadger_env, "#{fetch(:stage)}"

desc 'Restart the PurlListener'
namespace :deploy do
  task :restart do
    on primary(:app) do
      within current_path do
        with :rails_env => fetch(:rails_env) do
          execute :rake, 'listener:restart'
        end
      end
    end
  end
end
after 'deploy:published', 'deploy:restart'
