class RedmineBridge::WebhookJob < ActiveJob::Base
  def perform(integration, params)
    RedmineBridge::Registry[integration.connector_id].on_webhook_event(
      params: params,
      integration: integration,
      issue_repository: RedmineBridge::IssueRepository.new(integration)
    )
  end
end
