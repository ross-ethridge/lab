Rails.application.routes.draw do
  root 'chats#index'
  resources :chats, only: [:index, :create]
  resources :images, only: [:new, :create]
end