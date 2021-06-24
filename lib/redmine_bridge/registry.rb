# Registry for integration plugins
# Redmine bridge contain only Jira connector
module RedmineBridge::Registry
  extend Dry::Container::Mixin

  register :jira, RedmineBridge::JiraConnector.new(logger: Rails.logger)
  register :prometheus, RedmineBridge::PrometheusConnector.new
  register :gitlab, RedmineBridge::GitlabConnector.new(logger: Rails.logger)
end
