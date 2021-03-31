# frozen_string_literal: true

# Find integration and move to connector
class RedmineBridge::WebhookController < ActionController::API
  def create
    key = params[:key].presence || request.headers['Authorization']&.gsub(/^Bearer /, '')
    integration = BridgeIntegration.find_by!(key: key)

    RedmineBridge::WebhookJob.perform_later(integration, request.request_parameters)

    render json: {}
  end
end
