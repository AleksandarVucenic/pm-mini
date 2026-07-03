Rails.application.routes.draw do
  devise_for :users,
             path: "api/v1",
             path_names: { sign_in: "login", sign_out: "logout" },
             controllers: {
               sessions: "api/v1/sessions"
             },
             defaults: { format: :json }

  namespace :api do
    namespace :v1 do
      resources :users, only: [ :index ]
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
