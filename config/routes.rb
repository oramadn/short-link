Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post "/encode", to: "urls#encode"
  get "/decode/:short_code", to: "urls#decode"
end
