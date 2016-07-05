Rails.application.routes.draw do
  resources :collections, :defaults => { :format => 'json' }

  root :controller => 'about', :action => 'index'
  get 'about/version' => 'about#version'
  mount AboutPage::Engine => '/about(.:format)' # Or whever you want to access the about page

  resource :docs, :defaults => { :format => 'json' } do
    match 'deletes', :on => :collection, :via => [:get, :post]
    match 'changes', :on => :collection, :via => [:get, :post]
  end
end
