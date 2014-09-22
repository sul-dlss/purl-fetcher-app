class CollectionController < ApplicationController
  type_field = "active_fedora_model_s"
  id = "id"
  def index
   
    target_type = "Dor::Collection"

    response = Solr.get 'select', :params => {:q => "(#{type_field}):\"#{target_type}\")", :wt => :json, :fl ="#{id}" }
    
    #TODO Format response as list and return
  
  end
  
  def show
  #/collection/:druid?first_modified=TIME UTC?lastmodified=TIME_UTC
  
  #TODO Read in times from params
  #For time: http://lucene.apache.org/solr/4_8_1/solr-core/org/apache/solr/schema/TrieDateField.htm
  start_time = Time.at(0).utc.iso8601
  end_time = Time.now.utc.iso8601
  
  
  druid_for_collection = "info:fedora/" + :druid
  collection_field = "is_member_of_collection_s"
  time_field = "published_dt"
  
   
  response = Solr.get 'select', :params => {:q => "(#{collection_field}:\"#{druid_for_collection}\" OR #{id}:\"#{:druid}\") AND #{time_field}:[\"#{start_time}\" TO \"#{end_time}\"]", :wt => :json, :fl => "#{id} AND #{time_field} AND #{type_field}"}
  
  #TODO: If collection in response and said collection's druid != user provided druid, recursion!  
  
  #TODO: Format return response into a nested list and return it
  

  end
  
end
