resources :bridge_integrations do
  get 'check_connection', on: :member
end

post 'redmine_bridge/webhook/:key' => 'redmine_bridge/webhook#create'
post 'redmine_bridge/webhook' => 'redmine_bridge/webhook#create'
post 'redmine_bridge/operational_check/:key' => 'redmine_bridge/webhook#operational_check'
post 'redmine_bridge/operational_check' => 'redmine_bridge/webhook#operational_check'
