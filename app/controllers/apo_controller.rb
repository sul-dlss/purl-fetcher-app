#include Fetcher

class ApoController < ApplicationController

  # API call to get a full list of all APOs
  #
  # @return [requested_format] Will return json or xml (depending on what was requested) structure containing all of the published APOs.  If no format requested, defaults to json
  #
  # @param [querystring] Parameters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/apo.json  # gives all APOs in json format
  #   http://localhost:3000/apo?rows=0 # returns only the count of APOs in json format
  #   http://localhost:3000/apo.xml?first_modified=2014-01-01T00:00:00Z&last_modified=2014-02-01T00:00:00Z# returns only the APOs published in January of 2014 in XML format
  #   http://localhost:3000/apo?first_modified=2014-01-01T00:00:00Z # returns only the APOs published SINCE January of 2014 up until today in json format
  #   http://localhost:3000/apo?first_modified=2014-01-01T00:00:00Z&rows=0 # returns only the count of APOs published SINCE January of 2014 up until today in json format
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

  # API call to get a list of druids associated with a specific APO
  #
  # @return [requested_format] Will return json or xml (depending on what was requested) structure containing all of the published druids associated with a specific APO.
  #  If no format requested, defaults to json
  #
  # @param [string] druid of the APO requested
  #
  # @param [querystring] Parameters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/apo/druid:oo000oo0001.json  # gives all objects associated with this druid APO in json format
  #   http://localhost:3000/apo/druid:oo000oo0001?rows=0 # returns only the count of APOs in json format
  #   http://localhost:3000/apo/druid:oo000oo0001.xml?first_modified=2014-01-01T00:00:00Z&last_modified=2014-02-01T00:00:00Z# returns only the objects associated with this druid APO published in January of 2014 in XML format
  def show
  #TODO: Option for recursion 
  
  result=find_all_under(params, :apo)
  render_result(result)

  end
  
end
