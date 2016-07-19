require 'uri'
require 'nokogiri'
require 'is_it_working'
Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  # Check that the PURL NFS mount directory
  h.check :directory, :path => PurlFetcher::Application.config.solr_indexing['purl_document_path'], :permission => [:read]

  # Check that Solr is Working
  # h.check :rsolr, client: IndexerController.new.establish_solr_connection

  # Check that the Solr Core is Working solr may be up but the core itself can be down
  h.check :solr_okay do |status|
    if IndexerController.new.check_solr_core
      status.ok('solr core responds to select')
    else
      status.fail('solr core does not respond')
    end
  end
end
