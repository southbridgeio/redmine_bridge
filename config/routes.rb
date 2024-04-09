resources :bridge_integrations do
  get 'check_connection', on: :member
end

post 'redmine_bridge/webhook/:key' => 'redmine_bridge/webhook#create'
post 'redmine_bridge/webhook' => 'redmine_bridge/webhook#create'
