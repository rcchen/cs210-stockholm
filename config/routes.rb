Cs210Stockholm::Application.routes.draw do
  
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

  # This is a registration URL
  get "users/login"
  post "users/login"
  get "users/register"
  post "users/register"
  get "users/profile"
  get "users/logout"

  #These routes are associated with the line graph
  #^ I think this is deprecated -  trying to associate line with api above
  #get "graph/line_filter"
  #post "graph/get_line"
  #get "graph/line"

  #These routes are associated with the dashboard
  get "dashboard", to: "dashboard#dashboard"

  root 'welcome#index'

end
