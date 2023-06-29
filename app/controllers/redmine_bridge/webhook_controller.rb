# frozen_string_literal: true

# Find integration and move to connector
class RedmineBridge::WebhookController < ActionController::API
  def create
    key = params[:key] || request.headers['X-Gitlab-Token'] || request.headers['Authorization']&.gsub(/^Bearer /, '')
    integration = BridgeIntegration.find_by(key: key)

    return head :forbidden unless integration

    # wait 3 seconds - because we have race conditions, when we create jira issue,
    # got webhook about creation, but not yet save in database external_id with created
    # jira issue id. Which causes duplications
    RedmineBridge::WebhookJob.set(wait: 3.seconds).perform_later(integration, request.request_parameters)

    render json: {}
  end
end
