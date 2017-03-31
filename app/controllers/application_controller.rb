class ApplicationController < ActionController::Base

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery unless: -> { request.format.json? }, with: :exception

  def default
    render plain: 'ok' # just render a static 200 so we don't get the default rails app home page on root
  end

  private

    def page_params
      params.permit(:page)
    end

    def per_page_params
      params.permit(:per_page)
    end

    def druid_param
      params.require(:druid)
    end
end
