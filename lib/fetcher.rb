# A mixin module that is part of application controller, this provides base functionality to all classes
module Fetcher
  @@field_return_list = "#{ID_Field} AND #{Last_Changed_Field} AND #{Type_Field} AND #{Title_Field}"
  

  # Given the user's querystring parameters, and a fedora type, return a solr response containing all of the objects associated with that type (potentially limited by rows or date if specified by the user)
  #
  # @return [hash] solr response
  #
  # @param params [hash] querystring parameters from user, which could be an empty hash
  # @param ftype [string] fedora object type, could be :apo or :collection
  #
  # Example:
  #   find_all_fedora_type(params,:apo)
  def find_all_fedora_type(params,ftype)
    
    #ftype should be :collection or :apo (or other symbol if we added more since this was updated)

    times = get_times(params)

    solrparams={:q => "#{Type_Field}:\"#{Fedora_Types[ftype]}\" AND #{Last_Changed_Field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]", :wt => :json, :fl => @@field_return_list}
    get_rows(solrparams,params)
    
    response = Solr.get 'select', :params => solrparams
    
    return determine_proper_response(params, response)
  end

  # Given the user's querystring parameters (including the ID paramater, which represents the druid), and a fedora object type, return a solr response containing all of the objects controlled by that druid of that type (potentially limited by rows or date if specified by the user)
  #
  # @return [hash] solr response
  #
  # @param params [hash] querystring parameters from user, which must include :id of the druid
  # @param controlled_by [string] fedora object type, could be :apo or :collection
  #
  # Example:
  #   find_all_fedora_type(params,:apo)  
  def find_all_under(params, controlled_by)
    #controlled_by should be :collection or :apo (or other symbol if we added more since this was updated)
    times = get_times(params)
    
    solrparams= {
      :q => "(#{Controller_Types[controlled_by]}:\"#{druid_of_controller(params[:id])}\" OR #{ID_Field}:\"#{druid_for_solr(params[:id])}\") AND #{Last_Changed_Field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]", 
      :wt => :json,
      :fl => @@field_return_list
      }
      get_rows(solrparams,params)

    response = Solr.get 'select', :params => solrparams
  
    #TODO: If APO in response and said APO's druid != user provided druid, recursion!  
    
    return determine_proper_response(params, response)
  end

  # Given the user's querystring parameters (including the ID paramater, which represents the tag), return a solr response containing all of the objects associated with the supplied tag(potentially limited by rows or date if specified by the user)
  #
  # @return [hash] solr response
  #
  # @param params [hash] querystring parameters from user, which must include :id of the tag
  #
  # Example:
  #   find_by_tag(params)    
  def find_by_tag(params)
    times = get_times(params)

    solrparams={
      :q => "(#{Controller_Types[:tag]}:\"#{params[:tag]}\") AND #{Last_Changed_Field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]", 
      :wt => :json,
      :fl =>  @@field_return_list
      }

      get_rows(solrparams,params)
    
    response = Solr.get 'select', :params => solrparams

    return determine_proper_response(params, response)

  end

  # Given a druid without the druid prefix (e.g. oo000oo0001), add the prefixes needed for querying solr for controllers
  #
  # @return [string] druid
  #
  # @param druid [string] druid
  #
  # Example:
  #   druid_for_controller('oo000oo0001') # returns info:fedora/druid:oo000oo0001
  def druid_of_controller(druid)
    return Fedora_Prefix + Druid_Prefix + parse_druid(druid)
  end

  # Given a druid without the druid prefix (e.g. oo000oo0001), add the prefix needed for querying solr
  #
  # @return [string] druid
  #
  # @param druid [string] druid
  #
  # Example:
  #   druid_for_solr('oo000oo0001') # returns druid:oo000oo0001
  def druid_for_solr(druid)
    return Druid_Prefix + parse_druid(druid)
  end
  
  # Given a druid in any format (e.g. oo000oo0001 or druid:oo00oo0001), returns only the numberical part, stripping the "druid:" prefix
  # If invalid druid passed, will raise an exception.
  #
  # @return [string] druid
  #
  # @param druid [string] druid
  #
  # Example:
  #   parse_druid('oo000oo0001') # returns oo000oo0001
  #   parse_druid('druid:oo000oo0001') # returns oo000oo0001
  #   parse_druid('junk') # throws an exception
  def parse_druid(druid)
    matches = druid.match(/[a-zA-Z]{2}\d{3}[a-zA-Z]{2}\d{4}/)
    matches.nil? ? raise("invalid druid") : matches[0]
  end
 
  # Given a hash containing "first_modified" and "last_modified", ensures the date formats are valid, converts to proper ISO8601 if they are.
  # If first_modified is missing, sets to the earliest possible date.
  # If last_modified is missing, sets to current date/time.
  # If invalid dates are passed in, throws an exception.
  #
  # @return [hash] containing :first and :last keys with proper vaues
  #
  # @param p [hash] which includes :first_modified and :last_modified keys as coming in from the querystring from the user
  #
  # Example:
  #   get_times(:first_modified=>'01/01/2014') # returns {:first=>'2014-01-01T00:00:00Z',last:'CURRENT_DATETIME_IN_UTC_ISO8601'}
  #   get_times(:first_modified=>'junk') # throws exception
  #   get_times(:first_modified=>'01/01/2014',:last_modified=>'01/01/2015') # returns {:first=>'2014-01-01T00:00:00Z',last:'2015-01-01T00:00:00Z'}
  def get_times(p = {})
    params = p || {}
    first_modified = params[:first_modified] || Time.at(0).utc.iso8601
    last_modified = params[:last_modified] || Date.tomorrow.to_time.utc.iso8601
    begin 
      first_modified_time=Time.parse(first_modified)
      last_modified_time=Time.parse(last_modified)
    rescue
      raise "invalid time paramaters"
    end
    start_time = first_modified_time.utc.iso8601 
    end_time = last_modified_time.utc.iso8601 
    raise "start time is before end time" if start_time >= end_time
    return {:first => start_time, :last => end_time}
  end

  # Given a params hash that will be passed to solr, adds in the proper :rows value depending on if we are requesting a certain number of rows or not
  #
  # @return [hash] solr params hash
  #
  # @param solrparams [hash] solr params has to be altered
  # @param params [hash] query string params from user
  #
  def get_rows(solrparams,params)
    params.has_key?(:rows) ? solrparams.merge!(:rows => params[:rows]) : solrparams.merge!(:rows => 100000000)  # if user passes in the rows they want, use that, else just return everything
  end
  
  #Given a solr response hash, create a json string to properly return the data.
  #
  #
  #
  #
  #
  #
  def format_json(params, response)
    
    all_json = {}
    times = get_times(params)

    #Create A Hash that contains an empty list for each Fedora Type
    Fedora_Types.each do |key, value|
      all_json.store(value.to_sym, [])
    end
    
    response[:response][:docs].each do |doc|
      #First determine type of this specific druid
      type = doc[Type_Field.to_sym][0]
      
      #Make the JSON for this druid
      j = {:druid => doc[ID_Field.to_sym], :latest_change => determine_latest_date(times, doc[Last_Changed_Field.to_sym]), :title => doc[Title_Field.to_sym]}

      #Append this little json stub to its proper parent array
      all_json[type.to_sym] << j
    end
    
    #Now we need to delete any nil arrays and sum the ones that aren't nil 
    total_count = 0 
    a = []
    all_json.each do |key, value|
      if value.size == 0
        all_json.delete(key)
      else
        a << {key => value.size}
        total_count += value.size
      end
    end
    a << {:total_count => total_count}
    all_json.store(:counts, a)
    
    return all_json
    
  end
  
  #This function determines if the user asked for just a count of the item or a full druid list from the item and will return the proper choice
  #
  #
  #
  #
  #
  def determine_proper_response(params, response)
    # :rows=0 indicates they just want a count
    if params[:rows] == '0'
      return response[:response][:numFound]
    else
      return format_json(params, response)
    end
  
  end
  
  # This function determines the latest date modified/changed in the appropriate timeframe
  # If no timeframe provided in the params, it is just the latest date.  Otherwise it uses
  # first_modified and/or last_modified as the bounding dates and returns the latest date in
  # the requested timeframe
  def determine_latest_date(times, last_changed)
      #latest_date = Time.at(0).utc.iso8601
      
      #Sort with latest date first
      changes_sorted = last_changed.sort.reverse
      
      prev_change = changes_sorted[0] #There has to be at least one, otherwise item was not published and could not have been harvested
      changes_sorted.each do |c|
        
        #all changes_sorted have to be equal or greater than times[:first], otherwise Solr would have had zero results for this, we just want the first one earlier than :last
        if c <= times[:last]
          return c
        end
      end
      
      #If we get down here we have a big problem, because there should have been at least one date earlier than times[:last]
      raise("Error finding latest changed date, failed to find one")

      

  end
  
end
