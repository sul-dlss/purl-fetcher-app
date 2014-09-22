#include Fetcher

class CollectionController < ApplicationController
  type_field = "active_fedora_model_s"
  id = "id"
  def index
    #TODO:  Allow for param to just get count
    #target_type = "Dor::Collection"
    #response = Solr.get 'select', :params => {:q => "(#{type_field}):\"#{target_type}\")", :wt => :json, :fl ="#{id}" }
    
    return find_all_fedora_type(:collection)
  
  end
  
  def show
  #/collection/:druid?first_modified=TIME UTC?lastmodified=TIME_UTC
  #TODO:  Allow for param to just get count
  
  return find_all_under(params, :collection)

  end
  
end
