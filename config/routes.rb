Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions:      "users/sessions",
    passwords:     "users/passwords",
    registrations: "users/registrations",
    confirmations: "users/confirmations"
  }

  resources :municipalities, only: %i[ index ]
  resources :machi_repos do
    collection do
      get :search
    end

    resources :chats, only: %i[ index create ], module: :machi_repos do
      collection do
        get :load_more
      end
    end
  end

  resources :tests, only: %i[ index destroy ]

  root "tops#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
