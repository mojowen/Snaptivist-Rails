SnaptivistRails::Application.routes.draw do
  devise_for :users, :controllers => {:omniauth_callbacks => "my_omniauth_callbacks"}, :path =>''

  match '/save' => 'home#save'
  match '/' => 'home#home'
  match '/analytics' => 'home#analytics'
  match '/list' => 'home#list'
end
