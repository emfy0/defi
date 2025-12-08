Rails.application.routes.draw do
  resource :session
  resources :users, only: %i[create new]

  resources :offers, only: %i[create new index show] do
    resources :contracts, only: [:new, :create]
  end

  resources :contracts, only: [:show, :index] do
    member do
      post :check_deposit
      post :payment_paid
      post :sign_release
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "offers#index"
end
