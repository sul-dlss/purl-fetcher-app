class ApoController < ApplicationController
  
  type_field = "active_fedora_model_s"
  id = "id"
  def index
    #Currently have no publically visible APOS
    #objectType_t = adminpolicy
    #"active_fedora_model_s": ["Dor::AdminPolicyObject"]
    target_type = "Dor::AdminPolicyObject"

    response = Solr.get 'select', :params => {:q => "(#{type_field}):\"#{target_type}\")", :wt => :json, :fl ="#{id}" }
    
    #TODO Format response as list and return
  
  end
  
  def show
  #/apo/:druid?first_modified=TIME UTC?lastmodified=TIME_UTC
  
  #TODO Read in times from params
  #For time: http://lucene.apache.org/solr/4_8_1/solr-core/org/apache/solr/schema/TrieDateField.htm
  start_time = Time.at(0).utc.iso8601
  end_time = Time.now.utc.iso8601
  
  #Example for African Music APO:
  #Solr.get 'select', :params => {:q => '(is_governed_by_s:"info:fedora/druid:gn965yg6021" OR id:"druid:gn965yg6021") AND obj_last_mod_date_dt:["1970-08-19T23:00:09Z" TO "2014-09-19T23:00:09Z"]', :wt=> :json, :fl => 'id AND obj_last_mod_date_dt AND active_fedora_model_s'}
  
  druid_for_apo = "info:fedora/" + :druid
  apo_field = "is_governed_by_s"
  time_field = "published_dt"
  
   
  response = Solr.get 'select', :params => {:q => "(#{apo_field}:\"#{druid_for_apo}\" OR #{id}:\"#{:druid}\") AND #{time_field}:[\"#{start_time}\" TO \"#{end_time}\"]", :wt => :json, :fl => "#{id} AND #{time_field} AND #{type_field}"}
  
  #TODO: If APO in response and said APO's druid != user provided druid, recursion!  
  
  #TODO: Format return response into a nested list and return it
  

  end
  
  


end
