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
      get :load_more
    end

    resources :chats, only: %i[ index create destroy ], module: :machi_repos do
      collection do
        get :load_more
      end
      member do
        get :render_chat
      end
    end
  end

  resources :accounts, only: %i[ index destroy ]

  resources :helps, only: %i[ index ]

  root "tops#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
