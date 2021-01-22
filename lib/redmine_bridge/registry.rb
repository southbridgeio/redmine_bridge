# Registry for integration plugins
# Redmine bridge contain only Jira connector
module RedmineBridge::Registry
  extend Dry::Container::Mixin

  register(:jira) { RedmineBridge::JiraConnector.new }
end
