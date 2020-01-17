Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks"
  }
  root 'users#top'
  post '/callback' => "line_bot#callback"
  post '/test' => "line_bot#test"
  patch '/users/update' => 'users#update'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
