class CollectionsController < ApplicationController
  ##
  # API call to get a full list of all PURL collections
  #
  # @param [querystring] Parameters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #
  #  http://localhost:3000/collections
  #  http://localhost:3000/collections?rows=0
  #
  # @return [Array<String>] list of druids for all PURL collections
  #
  #
  #
  def index
    collections = Purl.where(object_type: 'collection')
    if params[:rows] == '0'
      respond_to do |format|
        format.json { render json: { size: collections.size }.to_json }
      end
    else
      respond_to do |format|
        format.json { render json: collections.to_a.map(&:druid).to_json }
      end
    end
  end

  ##
  # API call to get a list of PURL druids associated with a specific collection
  #
  # @param [querystring] Parameters can be specified in the querystring
  #   * rows = number of results to return (set to 0 to only get count)
  #
  #  http://localhost:3000/collections/druid:aa111bb2222
  #  http://localhost:3000/collections/druid:aa111bb2222?rows=0
  #
  # @return [Array<String>] list of druids for all PURLs that are members of the given collection
  #
  def show
    druid = params.require(:id)
    raise ArgumentError, "Invalid collection: #{druid}" unless Collection.find_by_druid(druid).present?

    purls = Purl.joins(:collections).where('collections.druid = ?', druid)
    if params[:rows] == '0'
      respond_to do |format|
        format.json { render json: { size: purls.size }.to_json }
      end
    else
      respond_to do |format|
        format.json { render json: purls.to_a.map(&:druid).to_json }
      end
    end
  end
end
