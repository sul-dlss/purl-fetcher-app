class TagsController < ApplicationController
  # List druids associated with a specific tag
  # Will render JSON or XML (depending on what was requested) structure containing all of the published DRUIDs associated with a specific tag.
  # Defaults to JSON.
  #
  # @param [string] tag requested, should be URL encoded if it contains special characters
  # @param [querystring] Parameters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/tags/sometag.json  # gives all objects associated with this tag format
  #   http://localhost:3000/tags/sometag?rows=0 # returns only the count of objects with this tag in json format
  #   http://localhost:3000/tags/sometag.xml?first_modified=2014-01-01T00:00:00Z&last_modified=2014-02-01T00:00:00Z# returns only the objects associated with this tag  published in January of 2014 in XML format
  def show
    result = find_by_tag(params)
    render_result(result)
  end

  # List all tags.
  # Will render JSON or XML (depending on what was requested) structure containing all of the published tags.
  # Defaults to JSON.
  #
  # @param [querystring] Parameters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/tags.json  # gives all tags in json format
  def index
    # TODO: Return a list of all tag_facet entries or their counts
    render_result(200)
  end
end
