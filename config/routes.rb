# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

namespace :jira do
  resources :issues, except: %i[new edit]
end
