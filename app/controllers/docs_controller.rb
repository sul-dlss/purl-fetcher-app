class DocsController < ApplicationController
  before_action :date_params

  # API call to get a full list of all purls modified between two times
  def changes
    @changes = Purl.where(deleted_at: nil)
                   .where(published_at: @first_modified..@last_modified)
                   .includes(:collections, :release_tags)
                   .page(params[:page])
                   .per(per_page_params[:per_page])
  end

  # API call to get a full list of all purl deletes between two times
  def deletes
    @deletes = Purl.where(deleted_at: @first_modified..@last_modified)
                   .page(params[:page])
                   .per(per_page_params[:per_page])
  end

  private

  # Supports `first_modified` and `last_modified` in ISO8601 date formats (in any timezone)
  #
  # We convert the parameters into Time objects here rather than wait for ActiveRecord
  # so that we can handle timezone differences and raise exceptions on bad input data
  # before the action
  def date_params
    @first_modified = Time.zone.at(0).iso8601 # default
    @first_modified = params[:first_modified].to_datetime if params[:first_modified].present?

    @last_modified = Time.zone.now.iso8601    # default
    @last_modified = params[:last_modified].to_datetime if params[:last_modified].present?
  end

  def per_page_params
    params.permit(:per_page)
  end
end
