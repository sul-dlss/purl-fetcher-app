class DocsController < ApplicationController

  # API call to get a full list of all purls modified between two times
  # @param [querystring] Parameters can be specified in the querystring
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/docs/changes  # gives all items modified from the Unix Epoch until now
  #   http://localhost:3000/docs/changes?first_modified=2014-01-01T00:00:00Z # returns only the modified documents SINCE January of 2014 up until today in json format
  def changes
    # TODO: Get from ActiveRecord
    # result = get_modified_from_solr(first_modified: params['first_modified'], last_modified: params['last_modified'])
    # render_result(result)
  end

  # API call to get a full list of all purl deletes between two times
  # @param [querystring] Parameters can be specified in the querystring
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/docs/deletes  # gives all items deleted from the Unix Epoch until now
  #   http://localhost:3000/docs/deletes?first_modified=2014-01-01T00:00:00Z # returns only the modified deleted SINCE January of 2014 up until today in json format
  def deletes
    # TODO: Get from ActiveRecord
    # result = get_deletes_list_from_solr(first_modified: params['first_modified'], last_modified: params['last_modified'])
    # render_result(result)
  end
end
