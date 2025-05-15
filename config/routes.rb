Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions:      "users/sessions",
    passwords:     "users/passwords",
    registrations: "users/registrations",
    confirmations: "users/confirmations"
  }

  resources :municipalities, only: %i[index]
  resources :machi_repos, only: %i[index new create]



  resources :tests, only: %i[index destroy]

  root "tops#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
