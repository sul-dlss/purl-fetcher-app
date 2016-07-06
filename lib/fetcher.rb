require 'active_support/inflector'

# A mixin module that is part of application controller, this provides base functionality to all classes
module Fetcher
  include ApplicationHelper

  @@field_return_list = "#{ID_Field} AND #{Last_Changed_Field} AND #{Type_Field} AND #{Title_Field} AND #{Title_Field_Alt} AND #{CatKey_Field}"

  # Run a solr query, and do some logging
  #
  # @param params [Hash] params to send to solr
  # @param method [String] type of query to send to solr (defaults to "select")
  # @return [Hash] solr response
  #
  # Example:
  #   response=run_solr_query(:q=>'dude')
  def run_solr_query(params, method = 'select')
    start_time = Time.now
    response = Solr.get method, :params => params
    elapsed_time = Time.now - start_time
    Rails.logger.info "Request from #{request.remote_ip} to #{request.fullpath} at #{Time.now}"
    Rails.logger.info "Solr query: #{params}"
    Rails.logger.info "Query run time: #{elapsed_time.round(3)} seconds (#{(elapsed_time / 60.0).round(2)} minutes)"
    response
 end

  # Given the user's querystring parameters, and a fedora type, return a solr response containing all of the objects associated with that type (potentially limited by rows or date if specified by the user)
  #
  # @param params [Hash] querystring parameters from user, which could be an empty hash
  # @param ftype [String] fedora object type, could be :collection
  # @return [Hash] solr response
  #
  # Example:
  #   find_all_fedora_type(params,:collection)
  def find_all_fedora_type(params, ftype)
    # ftype should be :collection (or other symbol if we added more since this was updated)
    date_range_q = get_date_solr_query(params)
    solrparams = {
      :q  => "#{Type_Field}:\"#{Fedora_Types[ftype]}\" #{date_range_q}",
      :wt => :json,
      :fl => @@field_return_list
    }
    get_rows(solrparams, params)
    response = run_solr_query(solrparams)
    determine_proper_response(params, response)
  end

  # Given the user's querystring parameters (including the ID paramater, which represents the druid), and a fedora object type, return a solr response containing all of the objects controlled by that druid of that type (potentially limited by rows or date if specified by the user)
  #
  # @param params [Hash] querystring parameters from user, which must include :id of the druid
  # @param controlled_by [String] fedora object type, could be :collection
  # @return [Hash] solr response
  #
  # Example:
  #   find_all_fedora_type(params,:collection)
  def find_all_under(params, controlled_by)
    # controlled_by should be :collection (or other symbol if we added more since this was updated)
    date_range_q = get_date_solr_query(params)
    solrparams = {
      :q  => "(#{Controller_Types[controlled_by]}:\"#{druid_of_controller(params[:id])}\" OR #{ID_Field}:\"#{druid_for_solr(params[:id])}\") #{date_range_q}",
      :wt => :json,
      :fl => @@field_return_list
    }
    get_rows(solrparams, params)
    response = run_solr_query(solrparams)
    determine_proper_response(params, response)
  end

  # Given a druid without the druid prefix (e.g. oo000oo0001), add the prefixes needed for querying solr for controllers
  #
  # @param druid [String] druid
  # @return [String] druid
  #
  # Example:
  #   druid_for_controller('oo000oo0001') # returns info:fedora/druid:oo000oo0001
  def druid_of_controller(druid)
    Fedora_Prefix + Druid_Prefix + parse_druid(druid)
  end

  # Given a druid without the druid prefix (e.g. oo000oo0001), add the prefix needed for querying solr
  #
  # @param druid [string] druid
  # @return [string] druid
  #
  # Example:
  #   druid_for_solr('oo000oo0001') # returns druid:oo000oo0001
  def druid_for_solr(druid)
    Druid_Prefix + parse_druid(druid)
  end

  # Given a druid in any format (e.g. oo000oo0001 or druid:oo00oo0001), returns only the numberical part, stripping the "druid:" prefix
  # If invalid druid passed, will raise an exception.
  #
  # @param druid [String] druid
  # @return [String] druid
  #
  # Example:
  #   parse_druid('oo000oo0001') # returns oo000oo0001
  #   parse_druid('druid:oo000oo0001') # returns oo000oo0001
  #   parse_druid('junk') # throws an exception
  def parse_druid(druid)
    matches = druid.match(/[a-zA-Z]{2}\d{3}[a-zA-Z]{2}\d{4}/)
    matches.nil? ? raise('invalid druid') : matches[0]
  end

  # Given a hash containing "first_modified" and "last_modified", ensures the date formats are valid, converts to proper ISO8601 if they are.
  # If first_modified is missing, sets to the earliest possible date.
  # If last_modified is missing, sets to current date/time.
  # If invalid dates are passed in, throws an exception.
  #
  # @param p [Hash] which includes :first_modified and :last_modified keys as coming in from the querystring from the user
  # @return [Hash] containing :first and :last keys with proper vaues
  #
  # Example:
  #   get_times(:first_modified=>'01/01/2014') # returns {:first=>'2014-01-01T00:00:00Z',last:'CURRENT_DATETIME_IN_UTC_ISO8601'}
  #   get_times(:first_modified=>'junk') # throws exception
  #   get_times(:first_modified=>'01/01/2014',:last_modified=>'01/01/2015') # returns {:first=>'2014-01-01T00:00:00Z',last:'2015-01-01T00:00:00Z'}
  def get_times(p = {})
    params = p || {}
    first_modified = params[:first_modified] || Time.zone.at(0).iso8601
    last_modified = params[:last_modified] || yTenK
    begin
      first_modified_time = Time.zone.parse(first_modified).iso8601
      last_modified_time = Time.zone.parse(last_modified).iso8601
    rescue
      raise 'invalid time paramaters'
    end
    raise 'start time is before end time' if first_modified_time >= last_modified_time
    {:first => first_modified_time, :last => last_modified_time}
  end

  # Given a hash containing "first_modified" and "last_modified", returns the solr query part to append to the overall query to properly return dates, which my be blank if user asks for just registered objects
  #
  # @param p [hash] which includes :first_modified and :last_modified keys as coming in from the querystring from the user
  # @return [string] solr query part
  #
  # Example:
  #   get_date_solr_query(:first_modified=>'01/01/2014') # returns "and published_dt:["2014-01-01T00:00:00Z" TO "CURRENT_DATETIME"]"
  #   get_date_solr_query(:first_modified=>'01/01/2014',:status=>'registered') # returns ""

  def get_date_solr_query(p = {})
    times = get_times(p)
    registered_only?(p) ? '' : "AND #{Last_Changed_Field}:[\"#{times[:first]}\" TO \"#{times[:last]}\"]" # unless the user has asked for only registered items, apply the date range for published date
  end

  # Given a params hash that will be passed to solr, adds in the proper :rows value depending on if we are requesting a certain number of rows or not
  #
  # @param solrparams [Hash] solr params has to be altered
  # @param params [Hash] query string params from user
  # @return [Hash] solr params hash
  #
  def get_rows(solrparams, params)
    params.key?(:rows) ? solrparams.merge!(:rows => params[:rows]) : solrparams.merge!(:rows => 100000000) # if user passes in the rows they want, use that, else just return everything
  end

  # Given a params hash from the user, tells us if they only want registered items (ignoring accessioning and date ranges)
  #
  # @param params [Hash] query string params from user
  # @return [Boolean] true or false
  #
  def registered_only?(params)
    (params && params[:status] && params[:status].downcase) == 'registered'
  end

  # Given a solr response hash, create a json string to properly return the data.
  #
  # @param params [Hash] query string params from user
  # @param response [Hash] solr response
  # @return [Hash] formatted json
  #
  def format_json(params, response)
    all_json = {}
    times = get_times(params)

    # Create A Hash that contains an empty list for each Fedora Type
    Fedora_Types.each do |key, value|
      all_json.store(value.pluralize.to_sym, [])
    end

    response[:response][:docs].each do |doc|
      # First determine type of this specific druid
      type = doc[Type_Field.to_sym][0]

      # Make the JSON for this druid

      title1 = doc[Title_Field.to_sym]
      title2 = doc[Title_Field_Alt.to_sym]
      title = title1.nil? ? title2.nil? ? '' : title2[0] : title1[0] # look in two different fields for a title and grab the other if the first is nil (setting title to blank if both are nil)

      j = {:druid => doc[ID_Field.to_sym], :latest_change => determine_latest_date(times, doc[Last_Changed_Field.to_sym]), :title => title}
      j[:catkey] = doc[CatKey_Field.to_sym][0] unless doc[CatKey_Field.to_sym].nil?

      # Append this little json stub to its proper parent array
      all_json[type.downcase.pluralize.to_sym] << j
    end

    # Now we need to delete any nil arrays and sum the ones that aren't nil
    total_count = 0
    a = {}
    all_json.each do |key, value|
      if value.size == 0
        all_json.delete(key)
      else
        a[key] = value.size
        total_count += value.size
      end
    end
    a[:total_count] = total_count
    all_json.store(:counts, a)
    all_json
  end

  # Determines if the user asked for just a count of the item or a full druid list for the item and
  # returns the proper response
  #
  # @param params [Hash] query string params from user
  # @param response [Hash] solr response
  # @return [Hash] properly formatted json
  #
  def determine_proper_response(params, response)
    # :rows=0 indicates they just want a count
    return response[:response][:numFound] if params[:rows] == '0'
    format_json(params, response)
  end

  # Determine the latest date modified/changed in the appropriate timeframe
  # If no timeframe provided in the params, it is just the latest date.  Otherwise it uses
  # first_modified and/or last_modified as the bounding dates and returns the latest date in
  # the requested timeframe
  #
  # @param times [Hash] properly formatted :first and/or :last dates
  # @param last_changed [Array] change dates from solr response
  # @return [String] latest modified/changed date
  #
  def determine_latest_date(times, last_changed)
    # Sort with latest date first
    return nil unless last_changed
    changes_sorted = last_changed.sort.reverse
    changes_sorted.each do |c|
      # all changes_sorted have to be equal or greater than times[:first], otherwise Solr would have had
      # zero results for this, we just want the first one earlier than :last
      return c if c <= times[:last] && c >= times[:first]
    end
    # If we get down here we have a big problem, because there should have been at least one date earlier than times[:last]
    raise 'Error finding latest changed date, failed to find one'
  end
end
