Rails.application.routes.draw do
  scope module: :v1, constraints: ApiConstraint.new(version: 1) do
    resource :docs, :defaults => { :format => 'json' }, :only => [:get] do
      get 'deletes'
      get 'changes'
    end

    resources :purls, defaults: { format: :json}, only: [:index, :show], param: :druid

    resources :collections, defaults: { format: :json}, only: [:index, :show], param: :druid  do
      member do
        get 'purls'
      end
    end
  end
end
