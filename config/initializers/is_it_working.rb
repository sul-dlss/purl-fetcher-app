require 'is_it_working'
Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  # Check that the PURL NFS mount directory (listener needs write ability)
  h.check :directory, :path => PurlFetcher::Application.config.app_config['purl_document_path'], :permission => [:read]
  h.check :directory, :path => PurlFetcher::Application.config.app_config['listener_path'], :permission => [:read, :write]
  h.check :active_record, :async => false
  h.check :listener do |status|
    if Process.kill(0, ListenerLog.current.process_id)
      status.ok("listener is running")
    else
      status.fail("listener is not running")
    end
  end
end
