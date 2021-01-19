# Registry for integration plugins
# Redmine bridge contain only Jira connector
module RedmineBridge::Registry
  extend Dry::Container::Mixin

  register(:jira) { Jira.new }
  register(:trello) { Jira.new }
end
