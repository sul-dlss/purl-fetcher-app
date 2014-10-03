require 'rsolr'

class ApplicationController < ActionController::Base
  include Fetcher
  
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
    
  protected 
  # TODO this is where we take a solr response and convert it to the correct format
  def render_result(result)
    respond_to do |format|
      format.json {render :json=>result.to_json}
      format.xml {render :json=>result.to_xml}
    end  
  end
end
