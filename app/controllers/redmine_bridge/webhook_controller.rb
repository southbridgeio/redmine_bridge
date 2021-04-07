# frozen_string_literal: true

# Find integration and move to connector
class RedmineBridge::WebhookController < ActionController::API
  def create
    key = params[:key] || request.headers['X-Gitlab-Token'] || request.headers['Authorization']&.gsub(/^Bearer /, '')
    integration = BridgeIntegration.find_by!(key: key)

    RedmineBridge::WebhookJob.perform_later(integration, request.request_parameters)

    render json: {}
  end
end
