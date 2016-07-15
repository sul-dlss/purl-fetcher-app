server 'purl-fetcher-dev.stanford.edu', user: fetch(:user), roles: %w{web db app}
set :bundle_without, %w(sqlite test).join(' ')

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'development'