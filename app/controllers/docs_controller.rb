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

  def date_params
    @first_modified = params[:first_modified] || Time.zone.at(0).iso8601
    @last_modified = params[:last_modified] || Time.zone.now.iso8601
  end

  def per_page_params
    params.permit(:per_page)
  end
end
