resources :bridge_integrations

post 'redmine_bridge/webhook/:key' => 'redmine_bridge/webhook#create'
post 'redmine_bridge/webhook' => 'redmine_bridge/webhook#create'
