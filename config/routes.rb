Rails.application.routes.draw do

  get "healthz", to: "health#check"

  resources :posts
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
