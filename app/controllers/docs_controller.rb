class DocsController < ApplicationController

  before_action :date_params

  # API call to get a full list of all purls modified between two times
  # @param [querystring] Parameters can be specified in the querystring
  #   * first_modified = datetime in UTC (default: earliest possible date)
  #   * last_modified = datetime in UTC (default: current time)
  #
  # Example:
  #   http://localhost:3000/docs/changes  # gives all items modified from the Unix Epoch until now
  #   http://localhost:3000/docs/changes?first_modified=2014-01-01T00:00:00Z # returns only the modified documents SINCE January of 2014 up until today in json format
  # response is in the structure of {changes: [{druid: 'oo000oo0001', latest_change: '2015-01-01T00:00:00Z'}]}
  def changes
    changes = Purl.where(deleted_at: nil).where(indexed_at: @first_modified..@last_modified).includes(:collections, :release_tags)
    results = { changes: [] }
    changes.each do |change|
      results[:changes] <<
        { druid: change.druid,
          latest_change: change.indexed_at,
          true_targets: change.release_tags.where(release_type: true).map(&:name),
          false_targets: change.release_tags.where(release_type: false).map(&:name),
          collections: change.collections.map(&:druid) }
    end
    render_result(results)
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
    deletes = Purl.where(deleted_at: @first_modified..@last_modified)
    results = { deletes: [] }
    deletes.each { |delete| results[:deletes] << { druid: delete.druid, latest_change: delete.deleted_at } }
    render_result(results)
  end

  private

  def date_params
    @first_modified = params[:first_modified] || Time.zone.at(0).iso8601
    @last_modified = params[:last_modified] || Time.zone.now.utc.iso8601
  end

end
