require 'rsolr'

class ApplicationController < ActionController::Base
  include Fetcher
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  SOLR_URL=DorFetcherService::Application.config.solr_url
  
  
end
