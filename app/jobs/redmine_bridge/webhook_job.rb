class RedmineBridge::WebhookJob < ActiveJob::Base
  def perform(params)
    integration = BridgeIntegration.find_by!(key: params['key'])

    RedmineBridge::Registry[integration.connector_id].on_webhook_event(
      params: params,
      integration: integration,
      issue_repository: RedmineBridge::IssueRepository.new(integration)
    )
  end
end
