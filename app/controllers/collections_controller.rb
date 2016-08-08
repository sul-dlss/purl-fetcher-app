class CollectionsController < ApplicationController
  def index
    @collections = Purl.where(object_type: 'collection')
  end

  def show
  end
end
