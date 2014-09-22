module Fetcher
  def find_all_fedora_type(ftype)
    #ftype should be :collection or :apo (or other symbol if we added more since this was updated)
    response = Solr.get 'select', :params => {:q => "#{Type_Field}:\"#{Fedora_Types[ftype]}\"", :wt => :json, :fl =>"#{ID_Field}" }
    
    #TODO:  Call JSON Formatter
    
    return response
  end
  
  def find_all_under(params, controlled_by)
    #controlled_by should be :collection or :apo (or other symbol if we added more since this was updated)
    
    times = get_times(params)
    
  
    response = Solr.get 'select', :params => {:q => "(#{Controller_Types[controlled_by]}:\"#{druid_of_controller(params[:id])}\" OR #{ID_Field}:\"#{druid_for_solr(params[:id])}\") AND #{Last_Changed_Field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]", :wt => :json, :fl => "#{ID_Field} AND #{Last_Changed_Field} AND #{Type_Field}"}
  
    #TODO: If APO in response and said APO's druid != user provided druid, recursion!  
    
    #TODO: Format in JSON
    return response  
  end
  
  
  def druid_of_controller(druid)
    return Fedora_Prefix + Druid_Prefix + parse_druid(druid)
  end
  
  def druid_for_solr(druid)
    return Druid_Prefix + parse_druid(druid)
  end
  
  def parse_druid(druid)
    #If we have druid:foo, we want [1], if we just have foo we want [0]
    cleaned_druid = druid.split(":")[1] || druid.split(":")[0]
  end
  
  def get_times(params)
    #TODO: Check params for ISO 8601 Standard
    start_time = params[:first_modified] || Time.at(0).utc.iso8601
    end_time = params[:last_modified] || Time.now.utc.iso8601
    return {:first => start_time, :last => end_time}
    
  end
  
end