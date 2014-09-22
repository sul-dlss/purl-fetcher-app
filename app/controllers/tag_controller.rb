class TagController < ApplicationController
  #include Fetcher
  def show
  #/tag/:tag?first_modified=TIME UTC?lastmodified=TIME_UTC
  #TODO: Allow count option
  
  times = get_times(params)   
  response = Solr.get 'select', :params => {:q => "(#{Controller_Types[:tag]}:\"#{params[:tag]}\") AND #{Last_Changed_Field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]", :wt => :json, :fl => "#{ID_Field} AND #{Last_Changed_Field} AND #{Type_Field}"}
  
  #TODO: Format return response into a nested list and return it
  return response 

  end
  
end
