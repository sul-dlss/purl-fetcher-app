class CollectionController < ApplicationController

  # API call to get a full list of all collections
  #
  # @return [requested_format] Will return json or xml (depending on what was requested) structure containing all of the published collection.  If no format requested, defaults to json
  #
  # @param [querystring] Parameters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/collection.json  # gives all collections in json format
  #   http://localhost:3000/collection?rows=0 # returns only the count of collections in json format
  #   http://localhost:3000/collection.xml?first_modified=2014-01-01T00:00:00Z&last_modified=2014-02-01T00:00:00Z# returns only the collections published in January of 2014 in XML format
  #   http://localhost:3000/collection?first_modified=2014-01-01T00:00:00Z # returns only the collections published SINCE January of 2014 up until today in json format
  #   http://localhost:3000/collection?first_modified=2014-01-01T00:00:00Z&rows=0 # returns only the count of collections published SINCE January of 2014 up until today in json format
  def index

    result=find_all_fedora_type(params,:collection)
    render_result(result)
  
  end

  # API call to get a list of druids associated with a specific collection 
  #
  # @return [requested_format] Will return json or xml (depending on what was requested) structure containing all of the published druids associated with a specific collection.
  #  If no format requested, defaults to json
  #
  # @param [string] druid of the collection requested
  #
  # @param [querystring] Parameters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/collection/druid:oo000oo0001.json  # gives all objects associated with this collection  in json format
  #   http://localhost:3000/collection/druid:oo000oo0001?rows=0 # returns only the count of collection in json format
  #   http://localhost:3000/collection/druid:oo000oo0001.xml?first_modified=2014-01-01T00:00:00Z&last_modified=2014-02-01T00:00:00Z# returns only the objects associated with this collection  published in January of 2014 in XML format  
  def show
  
  result=find_all_under(params, :collection)
  render_result(result)

  end
  
end
