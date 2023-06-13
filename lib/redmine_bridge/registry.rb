# Registry for integration plugins
# Redmine bridge contain only Jira connector
module RedmineBridge::Registry
  extend Dry::Container::Mixin

  register :jira, ->(*args) { RedmineBridge::JiraConnector.new(*args) }
  register :prometheus, ->(*args) { RedmineBridge::PrometheusConnector.new(*args) }
  register :gitlab, ->(*args) { RedmineBridge::GitlabConnector.new(*args) }
end
