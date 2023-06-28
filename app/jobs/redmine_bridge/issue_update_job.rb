class RedmineBridge::IssueUpdateJob < ActiveJob::Base
  def perform(integration, external_issue, journal)
    RedmineBridge::Registry[integration.connector_id]
      .call(integration: integration)
      .on_issue_update(journal: journal,
                       external_issue: external_issue)
  end
end
