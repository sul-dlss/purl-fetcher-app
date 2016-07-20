Rails.application.routes.draw do
  resources :collections, defaults: { format: 'json' }, only: [:show, :index]

  root :controller => 'about', :action => 'index'
  get 'about/version' => 'about#version'
  mount AboutPage::Engine => '/about(.:format)' # Or whever you want to access the about page

  resource :docs, :defaults => { :format => 'json' }, :only => [:get] do
    get 'deletes'
    get 'changes'
  end
end
