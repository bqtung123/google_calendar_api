Rails.application.routes.draw do
  resources :tasks
  get 'example/redirect'
  get 'sessions/create'
  get 'sessions/destroy'
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  get 'home/index'
  root 'home#index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get 'auth/:provider/callback', to: 'sessions#create'
  # get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'

  resources :sessions, only: %i[create destroy]
  # Defines the root path route ("/")
  # root "articles#index"
  get '/get_google_calendar_client', to: 'example#get_google_calendar_client', as: 'get_google_calendar_client'
end
