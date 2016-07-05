class AboutController < ApplicationController
  def index
    render :text => 'ok', :status => 200
  end

  def version
    @result = {
      :app_name  => PurlFetcher::Application.config.app_name,
      :rails_env => Rails.env,
      :version   => PurlFetcher::Application.config.version,
      :last_restart => (File.exist?('tmp/restart.txt') ? File.new('tmp/restart.txt').mtime : 'n/a'),
      :last_deploy  => (File.exist?('REVISION') ? File.new('REVISION').mtime : 'n/a'),
      :solr_url  => PurlFetcher::Application.config.solr_url
    }

    respond_to do |format|
      format.json {render :json => @result.to_json}
      format.xml  {render :json => @result.to_xml(:root => 'status')}
      format.html {render}
    end
  end
end
