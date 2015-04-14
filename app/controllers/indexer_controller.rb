require 'rsolr'
require 'json'

class IndexerController < ActionController::Base
  include Indexer
  
  def index

    return true
  
  end
end