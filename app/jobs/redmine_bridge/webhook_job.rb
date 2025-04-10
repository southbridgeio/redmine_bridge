class RedmineBridge::WebhookJob < ActiveJob::Base
  def perform(integration, params, test: false)
    RedmineBridge::Registry[integration.connector_id]
      .call(integration: integration)
      .on_webhook_event(
        params: params,
        issue_repository: RedmineBridge::IssueRepository.new(integration),
        test: test,
    )
  end
end
