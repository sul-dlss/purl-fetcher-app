Rails.application.routes.draw do
  root :controller => 'about', :action => 'index'
  get 'about/version' => 'about#version'
  mount AboutPage::Engine => '/about(.:format)' # Or whever you want to access the about page

  resource :docs, :defaults => { :format => 'json' }, :only => [:get] do
    get 'deletes'
    get 'changes'
  end

  resources :purls, defaults: { format: :json}, only: [:index, :show], param: :druid

  get 'collections' => 'collections#index', defaults: { :format => 'json' }
  get 'collections/:id' => 'collections#show', defaults: { :format => 'json' },
    constraints: { id: /druid:[a-z]{2}[0-9]{3}[a-z]{2}[0-9]{4}/ }
end
