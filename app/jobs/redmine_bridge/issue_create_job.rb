class RedmineBridge::IssueCreateJob < ActiveJob::Base
  def perform(integration, external_issue)
    RedmineBridge::Registry[integration.connector_id]
      .call(integration: integration)
      .on_issue_create(external_issue: external_issue)
  end
end
