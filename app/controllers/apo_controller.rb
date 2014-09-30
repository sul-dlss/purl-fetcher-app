#include Fetcher

class ApoController < ApplicationController
  
  def index
    #/apo/
    #TODO: Option for count
    #Currently have no publically visible APOS
    #objectType_t = adminpolicy
    #"active_fedora_model_s": ["Dor::AdminPolicyObject"]
    #target_type = "Dor::AdminPolicyObject"
    #response = Solr.get 'select', :params => {:q => "(#{type_field}):\"#{target_type}\")", :wt => :json, :fl ="#{id}" }
    
    result=find_all_fedora_type(:apo)
    render_result(result)
    
  end
  
  def show
  #/apo/:druid?first_modified=TIME UTC&last_modified=TIME_UTC
  #TODO: Option for count
  #TODO: Option for recursion 
  
  #Example for African Music APO:
  #Solr.get 'select', :params => {:q => '(is_governed_by_s:"info:fedora/druid:gn965yg6021" OR id:"druid:gn965yg6021") AND obj_last_mod_date_dt:["1970-08-19T23:00:09Z" TO "2014-09-19T23:00:09Z"]', :wt=> :json, :fl => 'id AND obj_last_mod_date_dt AND active_fedora_model_s'}
  
  result=find_all_under(params, :apo)
  render_result(result)

  end
  
  


end
