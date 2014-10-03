#include Fetcher

class CollectionController < ApplicationController
  def index
    #TODO:  Allow for param to just get count
    #target_type = "Dor::Collection"
    #response = Solr.get 'select', :params => {:q => "(#{type_field}):\"#{target_type}\")", :wt => :json, :fl ="#{id}" }
    
    result=find_all_fedora_type(params,:collection)
    render_result(result)
  
  end
  
  def show
  #/collection/:druid?first_modified=TIME UTC?last_modified=TIME_UTC
  #TODO:  Allow for param to just get count
  
  result=find_all_under(params, :collection)
  render_result(result)

  end
  
end
