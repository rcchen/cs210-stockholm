Cs210Stockholm::Application.routes.draw do
  resources :collections

  resources :properties

  resources :entries

  get "welcome/index"
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # These routes are associated with the CSV parser
  get "parser/index"
  post "parser/verify"
  post "parser/upload"

  # These routes are associated with the create tool
  get "create/index"
  post "create/verify"

  # These routes are associated with the API
  get "api/index"
  get "api/:id", to: "api#explore"
  post "api/:id", to: "api#explore"
  get "api/bar/:id", to: "api#bar"
  post "api/bar/:id", to: "api#bar"
  get "api/line/:id", to: "api#line"
  post "api/line/:id", to: "api#line"

  #These routes are associated with the line graph
  #^ I think this is deprecated -  trying to associate line with api above
  get "graph/line_filter"
  post "graph/get_line"
  get "graph/line"

  #These routes are associated with the dashboard
  get "dashboard", to: "dashboard#dashboard"
  # You can have the root of your site routed with "root"
  root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
