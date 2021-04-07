class RedmineBridge::IssueUpdateJob < ActiveJob::Base
  def perform(integration, external_issue, journal)
    RedmineBridge::Registry[integration.connector_id].on_issue_update(journal: journal,
                                                                      integration: integration,
                                                                      external_issue: external_issue)
  end
end
