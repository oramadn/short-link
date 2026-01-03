Rails.application.routes.draw do
  root "pages#home"

  namespace :api do
    namespace :v1 do
      post "/encode", to: "urls#encode"
      get "/decode/:short_code", to: "urls#decode"
    end
  end
end
