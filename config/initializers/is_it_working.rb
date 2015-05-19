require 'uri'
require 'nokogiri'
require 'is_it_working'
Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  # Check that the PURL NFS mount directory
  h.check :directory, :path => "/purl", :permission => [:read]
  
  #Check that Solr is Working
  h.check :rsolr, :client => IndexerController.new.establish_solr_connection
end