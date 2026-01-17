# Registry for integration plugins
# Redmine bridge contains connectors for Jira, Prometheus, GitLab, Mattermost
module RedmineBridge::Registry
  CONNECTORS = {
    jira: ->(**kwargs) { RedmineBridge::JiraConnector.new(**kwargs) },
    prometheus: ->(**kwargs) { RedmineBridge::PrometheusConnector.new(**kwargs) },
    gitlab: ->(**kwargs) { RedmineBridge::GitlabConnector.new(**kwargs) },
    mattermost: ->(**kwargs) { RedmineBridge::MattermostConnector.new(**kwargs) }
  }.freeze

  def self.[](key)
    connector = CONNECTORS[key.to_sym]
    raise KeyError, "Unknown connector: #{key}" unless connector

    connector
  end

  def self.keys
    CONNECTORS.keys
  end
end
