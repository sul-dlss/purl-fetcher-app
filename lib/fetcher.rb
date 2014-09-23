module Fetcher
  def find_all_fedora_type(ftype, count_only=false)
    #ftype should be :collection or :apo (or other symbol if we added more since this was updated)

    params={:q => "#{Type_Field}:\"#{Fedora_Types[ftype]}\"", :wt => :json, :fl =>"#{ID_Field}"}
    params.merge!(:rows => 0) if count_only

    response = Solr.get 'select', :params => params
    #TODO:  Call JSON Formatter
    
    return response
  end
  
  def find_all_under(params, controlled_by, count_only=false)
    #controlled_by should be :collection or :apo (or other symbol if we added more since this was updated)
    
    times = get_times(params)
    
    params= {
      :q => "(#{Controller_Types[controlled_by]}:\"#{druid_of_controller(params[:id])}\" OR #{ID_Field}:\"#{druid_for_solr(params[:id])}\") AND #{Last_Changed_Field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]", 
      :wt => :json,
      :fl => "#{ID_Field} AND #{Last_Changed_Field} AND #{Type_Field}"
      }
    params.merge!(:rows => 0) if count_only

    response = Solr.get 'select', :params => params
  
    #TODO: If APO in response and said APO's druid != user provided druid, recursion!  
    
    #TODO: Format in JSON
    return response  
  end
  
  def find_by_tag(params, count_only=false)
    times = get_times(params)

    params={
      :q => "(#{Controller_Types[:tag]}:\"#{params[:tag]}\") AND #{Last_Changed_Field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]", 
      :wt => :json,
      :fl => "#{ID_Field} AND #{Last_Changed_Field} AND #{Type_Field}"
      }

    params.merge!(:rows => 0) if count_only
    response = Solr.get 'select', :params => params

    #TODO: Format return response into a nested list and return it
    return response

  end

  def druid_of_controller(druid)
    return Fedora_Prefix + Druid_Prefix + parse_druid(druid)
  end
  
  def druid_for_solr(druid)
    return Druid_Prefix + parse_druid(druid)
  end
  
  # given a druid in any format (e.g. oo000oo0001 or druid:oo00oo0001, returns only the numberical part, striping the "druid:" prefix -- if invalid druid passed, will raise an exception)
  def parse_druid(druid)
    matches = druid.match(/[a-zA-Z]{2}\d{3}[a-zA-Z]{2}\d{4}/)
    matches.nil? ? raise("invalid druid") : matches[0]
  end
  
  def get_times(params)
    first_modified = params[:first_modified]
    last_modified = params[:last_modified] 
    begin 
      first_modified_time=Time.parse(first_modified)
      last_modified_time=Time.parse(last_modified)
    rescue
      raise "invalid time paramaters"
    end
    start_time = first_modified_time.utc.iso8601 || Time.at(0).utc.iso8601
    end_time = last_modified_time.utc.iso8601 || Time.now.utc.iso8601
    return {:first => start_time, :last => end_time}
  end
  
end