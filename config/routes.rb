# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

post 'redmine_bridge/webhook/:key' => 'redmine_bridge/webhook#index'
