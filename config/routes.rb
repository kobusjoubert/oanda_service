Rails.application.routes.draw do
  root 'public#welcome', defaults: { format: 'json' }
  get 'public/welcome', defaults: { format: 'json' }
  devise_for :users, skip: [:sessions, :registrations, :passwords]

  namespace :indicators, only: [:index], defaults: { format: 'json' } do
    resources :point_and_figures, path: :point_and_figure
  end
end
