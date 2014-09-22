class TagController < ApplicationController
  type_field = "active_fedora_model_s"
  id = "id"
  
  def show
  #/tag/:tag?first_modified=TIME UTC?lastmodified=TIME_UTC
  
  #TODO Read in times from params
  #For time: http://lucene.apache.org/solr/4_8_1/solr-core/org/apache/solr/schema/TrieDateField.htm
  start_time = Time.at(0).utc.iso8601
  end_time = Time.now.utc.iso8601
  
  
  
  tag_field = "tag_t"
  time_field = "published_dt"
  
   
  response = Solr.get 'select', :params => {:q => "(#{tag_field}:\"#{tag}\") AND #{time_field}:[\"#{start_time}\" TO \"#{end_time}\"]", :wt => :json, :fl => "#{id} AND #{time_field} AND #{type_field}"}
  
  #TODO: If collection in response and said collection's druid != user provided druid, recursion!  
  
  #TODO: Format return response into a nested list and return it
  

  end
  
end
