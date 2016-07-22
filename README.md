[![Build Status](https://travis-ci.org/sul-dlss/purl-fetcher.png?branch=master)](https://travis-ci.org/sul-dlss/purl-fetcher) [![Coverage Status](https://coveralls.io/repos/github/sul-dlss/purl-fetcher/badge.svg?branch=master)](https://coveralls.io/github/sul-dlss/purl-fetcher?branch=master)


# purl-fetcher

A web service app that queries PURL to return info needed for indexing or other purposes.
This was forked from `dor-fetcher`.

## Setting up your environment

```bash
rvm install 2.1.2 # or use your favorite ruby manager

git clone https://github.com/sul-dlss/purl-fetcher.git

cd purl-fetcher

rvm use 2.1.2 # or switch as needed

bundle install
rake purlfetcher:config

# Edit config/*.yml files, adding passwords, etc.

rake jetty:start

rake purlfetcher:refresh_fixtures
rake purlfetcher:refresh_fixtures RAILS_ENV=test
```

## Running the application

```bash
rake jetty:start
rails server
```

## Logging

There are three log files:

* `indexing.log` - items that are being indexed (added or deleted)
* `[environment].log` - debug information for Solr queries
* `access.log` and `error.log` from Apache - traffic to the HTTP APIs

## Running tests

### To run the tests against the current VCR Cassettes:

```bash
rake
```

This command will run all of the tests, run rubocop and generate new documentation.

If you have a dependency related error or only want to run tests (no rubocop or docs):

```bash
bundle exec rspec
```

### To run the tests and generate new VCR Cassettes:

This can be used to refresh outdated cassettes or record cassettes for new tests.  With jetty stopped, you can start it, refresh the fixtures, rebuild the cassettes and run the tests using the following task:

```bash
rake rebuild_cassettes
```

Note, the above task will perform the following steps, which you can also try manually.  Note that if you are not using jetty, confirm you can connect to whatever you are recording from.
* Delete any current cassettes by renaming or removing the directory `spec/vcr_cassettes`.  If you are just adding cassettes this is not needed.
* Edit the VCR config in `spec/spec_helper.rb` to enable recording new episodes.
* Run the tests via:
```bash
bundle exec rspec
```
* To confirm the cassettes recorded stop jetty via:
```bash
rake jetty:stop
```
* If you are using something other than jetty, disable your connection (or turn your internet adapter off entirely)
* Run the tests again, all should pass.

## Generate documentation

To generate documentation into the "doc" folder:

```bash
yard
```

To keep a local server running with up to date code documentation that you can view in your browser:

```bash
yard server --reload
```
