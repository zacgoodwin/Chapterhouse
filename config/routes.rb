# frozen_string_literal: true

Rails.application.routes.draw do
  get 'up', to: 'rails/health#show', as: :rails_health_check

  mount GoodJob::Engine, at: 'good_job'
  mount PgHero::Engine, at: 'pghero'

  namespace :adminbook do
    resources :homebrews, only: %i[edit update] do
      get 'download_report', to: 'reports#download'
    end
    namespace :users do
      resources :notifications, except: %i[show]
      resources :platforms, only: %i[index]
    end
    resources :campaigns, only: %i[index]
    resources :users, only: %i[index]
    resources :feedbacks, only: %i[index]
    resources :notifications, only: %i[index new create]

    namespace :dnd5 do
      resources :characters, only: %i[index]
    end
    namespace :dnd2024 do
      resources :characters, only: %i[index]
      resources :recipes, only: %i[index new create]
    end
    namespace :tlc do
      resources :feats, except: %i[show]
      resources :spells, except: %i[show]
      resources :items, except: %i[show]
    end

    resources :items, except: %i[show]
    resources :spells, except: %i[show]
    resources :feats, except: %i[show]

    get '/', to: 'welcome#index'
  end

  namespace :frontend do
    namespace :bots do
      resources :characters, only: %i[] do
        post :create, on: :member
      end
    end
    resources :bots, only: %i[create]
    namespace :homebrews do
      resources :books, only: %i[index update]
      get ':provider', to: 'list#index'
    end
    resources :homebrews, only: %i[index]

    resources :characters, only: %i[index show destroy] do
      resources :notes, only: %i[index create update destroy], module: 'characters'
      resources :resources, only: %i[create update destroy], module: 'characters'
      resources :custom_resources, only: %i[index create update destroy], module: 'characters'

      scope ':provider' do
        resources :items, only: %i[index create update destroy], module: 'characters' do
          resources :consume, only: %i[create], module: 'items'
        end
        resources :bonuses, only: %i[index create update destroy], module: 'characters' do
          resources :consume, only: %i[create], module: 'bonuses'
        end
        resources :feats, only: %i[update], module: 'characters'
      end
    end

    get ':provider/items', to: 'items#index'
    namespace :info do
      resources :items, only: %i[show]
    end
    resource :users, only: %i[update destroy] do
      resources :feedbacks, only: %i[create], module: 'users'
      resources :notifications, only: %i[index], module: 'users' do
        get 'unread', on: :collection
      end
      resources :monitoring, only: %i[create], module: 'users'
      resource :info, only: %i[show], module: 'users'
    end

    namespace :dnd5 do
      resources :characters, only: %i[create update] do
        post :import, on: :collection
        resources :spells, only: %i[index create update destroy], module: 'characters'
        resources :rest, only: %i[create], module: 'characters'
        resources :health, only: %i[create], module: 'characters'
      end
      resources :spells, only: %i[index]
    end

    namespace :dnd2024 do
      resources :characters, only: %i[create update] do
        post :import, on: :collection
        scope module: :characters do
          resources :spells, only: %i[index create update destroy]
          resources :rest, only: %i[create]
          resources :craft, only: %i[index create]
          resources :talents, only: %i[index create]
          resources :homebrew_items, only: %i[create]
          resources :items, only: %i[] do
            resources :upgrade, only: %i[create], module: :items
          end
        end
      end
      resources :spells, only: %i[index show]
    end

    scope ':provider' do
      namespace :tags do
        scope ':type' do
          get ':id', action: :show
        end
      end
    end

    resources :campaigns, only: %i[index show create destroy] do
      resources :notes, only: %i[index create update destroy], module: 'campaigns'
      resource :join, only: %i[show create destroy], module: :campaigns

      scope ':provider' do
        resources :items, only: %i[index create update destroy], module: 'campaigns' do
          post 'send_item', on: :member
        end
      end
    end
  end

  namespace :homebrews_v2 do
    resources :homebrews, only: %i[index show] do
      post :batch_destroy, on: :collection
    end
    resources :publications, only: %i[index create destroy]

    namespace :dnd2024 do
      resources :races, only: %i[show destroy]
      resources :backgrounds, only: %i[show destroy]
      resources :subclasses, only: %i[show destroy]
      resources :feats, only: %i[index show destroy] do
        post :batch_destroy, on: :collection
      end
      resources :spells, only: %i[index show destroy]
      resources :books, only: %i[index show create update destroy] do
        get :for_items, on: :collection
      end
    end

    namespace :tlc do
      resources :species, only: %i[show destroy]
      resources :subclasses, only: %i[show destroy]
      resources :feats, only: %i[index show destroy] do
        post :batch_destroy, on: :collection
      end
    end

    resources :books, only: %i[] do
      resources :items, only: %i[create destroy], module: :books
    end

    namespace :users do
      resources :books, only: %i[update]
      resources :upvotes, only: %i[update]
    end
  end

  namespace :webhooks do
    resource :discord, only: %i[create]
  end

  namespace :owlbear do
    resources :campaigns, only: %i[show]
  end

  scope '(:locale)', locale: /#{I18n.available_locales.join('|')}/, defaults: { locale: nil } do
    scope module: :web do
      resource :dashboard, only: %i[show]
      resource :homebrews, only: %i[show]
      resources :characters, only: %i[show]

      resources :campaigns, only: %i[] do
        resource :join, only: %i[show], module: :campaigns
      end

      get 'privacy', to: 'welcome#privacy'
      get 'bot_commands', to: 'welcome#bot_commands'
      get 'tips', to: 'welcome#tips'
      get 'changelogs', to: 'welcome#changelogs'
      get 'too_many_requests', to: 'welcome#too_many_requests'
    end

    root 'web/welcome#index'
  end
end
