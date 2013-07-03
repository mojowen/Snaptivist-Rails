SnaptivistRails::Application.routes.draw do
  devise_for :users, :controllers => {:omniauth_callbacks => "my_omniauth_callbacks"}

  match '/save' => 'home#save'
  match '/' => 'home#home'
  match '/:photo_name' => 'home#photo', :via => :get
end
