SnaptivistRails::Application.routes.draw do
  devise_for :users, :controllers => {:omniauth_callbacks => "my_omniauth_callbacks"}

  match '/save' => 'home#save'
  match '/' => 'home#home'
end
