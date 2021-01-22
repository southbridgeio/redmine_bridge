# frozen_string_literal: true

# Find integration and move to connector
class RedmineBridge::WebhookController < ActionController::API
  def create
    return render json: {}, status: 404 unless integration

    result = connector.on_webhook_event(
      request: request,
      integration: integration,
      issue_repository: RedmineBridge::IssueRepository.new(integration)
    )

    render json: result.to_json
  end

  private

  def integration
    @integration ||= BridgeIntegration.find_by(key: params[:key])
  end

  def connector
    RedmineBridge::Registry[integration.connector_id]
  end
end
