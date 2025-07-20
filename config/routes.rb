Rails.application.routes.draw do
  namespace :accounts do
    resource :email, only: %i[ edit update ]
    resource :password, only: %i[ new create edit update ]
    resource :deactivation, only: [] do
      get :confirm
      delete :destroy
    end
  end
  devise_for :users, controllers: {
    sessions:      "users/sessions",
    passwords:     "users/passwords",
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  resources :users, only: %i[] do
    collection do
      get :followings
      get :load_more_followings
    end
  end
  resources :follows, only: %i[ create destroy ]
  resources :profiles, only: %i[ show new create edit update ]
  resources :municipalities, only: %i[ index ]
  resources :machi_repos do
    collection do
      get :search
      get :load_more
      get :my_machi_repos
      get :load_more_my_machi_repos
      get :bookmarks
      get :load_more_bookmarks
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
  resources :bookmarks, only: %i[ create destroy ]
  resources :tutorials, only: %i[ new create ]
  resources :accounts, only: %i[ index destroy ]
  resources :communities do
    collection do
      get :search
      get :scout
    end

    member do
      post :join, to: "community_memberships#join"
      patch :approve, to: "community_memberships#approve", as: :approve_member
      patch :reject, to: "community_memberships#reject", as: :reject_member
      delete :cancel, to: "community_memberships#cancel"
      delete :withdraw, to: "community_memberships#withdraw"
    end
  end
  resources :helps, only: %i[ index ]
  get "/terms", to: "pages#terms", as: :terms
  get "/privacy", to: "pages#privacy", as: :privacy
  root "tops#index"

  mount ActionCable.server => "/cable"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
