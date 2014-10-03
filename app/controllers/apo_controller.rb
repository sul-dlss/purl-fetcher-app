#include Fetcher

class ApoController < ApplicationController

  # API call to get a full list of all APOs
  #
  # @return [requested_format] Will return json or xml (depending on what was requested) structure containg all of the published APOs.  If no format requested, defaults to json
  #
  # @param [querystring] Paramters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/apo.json  # gives all APOs in json format
  #   http://localhost:3000/apo?count_only=true # returns only the count of APOs in json format
  #   http://localhost:3000/apo.xml?first_modified=2014-01-01T00:00:00Z&last_modified=2014-02-01T00:00:00Z# returns only the APOs published in January of 2014 in XML format
  #   http://localhost:3000/apo?first_modified=2014-01-01T00:00:00Z # returns only the APOs published SINCE January of 2014 up until today in json format
  #   http://localhost:3000/apo?first_modified=2014-01-01T00:00:00Z&count_only=true # returns only the count of APOs published SINCE January of 2014 up until today in json format
  def index
    #/apo/
    #TODO: Option for count
    #Currently have no publically visible APOS
    #objectType_t = adminpolicy
    #"active_fedora_model_s": ["Dor::AdminPolicyObject"]
    #target_type = "Dor::AdminPolicyObject"
    #response = Solr.get 'select', :params => {:q => "(#{type_field}):\"#{target_type}\")", :wt => :json, :fl ="#{id}" }
    
    result=find_all_fedora_type(params,:apo)
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
