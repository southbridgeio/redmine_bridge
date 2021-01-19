resources :bridge_integrations

post 'redmine_bridge/webhook/:key' => 'redmine_bridge/webhook#create'
