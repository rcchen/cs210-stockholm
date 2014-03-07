Cs210Stockholm::Application.routes.draw do

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # These routes are associated with the create tool
  get "create/index"
  post "create/verify"

  # These routes are associated with the API
  get "api/:id", to: "api#explore"
  post "api/:id", to: "api#explore"

  # These routes are associated with the dataset
  get "dataset/create"
  post "dataset/create"
  get "dataset/verify"
  post "dataset/verify"
  get "dataset/:id", to: "dataset#view"
  get "dataset/:id/edit", to: "dataset#edit"
  post "dataset/:id/edit", to: "dataset#edit"
  get "dataset/:id/destroy", to: "dataset#destroy"

  # These routes are associated with the worksheet
  get "worksheet/create"
  post "worksheet/create"
  get "worksheet/:id", to: "worksheet#view"
  get "worksheet/:id/edit", to: "worksheet#edit"
  post "worksheet/:id/edit", to: "worksheet#edit"
  
  # These routes are associated with visualizations
  get "visualization/create"
  post "visualization/create"
  get "visualization/:id", to: "visualization#view"
  get "visualization/:id/edit", to: "visualization#edit"
  post "visualization/:id/edit", to: "visualization#edit"

  # This is a registration URL
  get "users/login"
  post "users/login"
  get "users/register"
  post "users/register"
  get "users/profile"
  get "users/logout"

  #These routes are associated with the dashboard
  get "dashboard", to: "dashboard#dashboard"

  root 'welcome#index'

end
