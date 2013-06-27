SnaptivistRails::Application.routes.draw do
  match '/save' => 'home#save'
  match '/' => 'home#home'
end
