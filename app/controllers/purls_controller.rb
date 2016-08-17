class PurlsController < ApplicationController
  ##
  # Returns all Purls with filtering options
  def index
    @purls = Purl.all
                 .includes(:collections, :release_tags)
                 .filter(filter_params)
                 .page(page_params[:page])
                 .per(per_page_params[:per_page])
  end

  ##
  # Returns a specific Purl by a Purl
  def show
    @purl = Purl.find_by_druid(druid_param)
  end

  private

  def filter_params
    object_type_param
  end

  def object_type_param
    params.permit(:object_type)
  end

  def druid_param
    params.require(:druid)
  end
end
