require 'is_it_working'
Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  # Check that the PURL NFS mount directory
  h.check :directory, :path => PurlFetcher::Application.config.app_config['purl_document_path'], :permission => [:read]
  h.check :active_record, :async => false
end
