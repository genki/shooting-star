ActionController::Routing::Routes.draw do |map|
  map.resources :chats

  map.connect '', :controller => 'chats'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
end
