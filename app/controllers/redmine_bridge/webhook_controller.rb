# frozen_string_literal: true

# Find integration and move to connector
class RedmineBridge::WebhookController < ActionController::API
  def create
    key = params[:key] || request.headers['X-Gitlab-Token'] || request.headers['Authorization']&.gsub(/^Bearer /, '')
    integration = BridgeIntegration.find_by(key: key)

    return head :forbidden unless integration
    return head :forbidden unless validate_params(integration, request.request_parameters)

    # wait 3 seconds - because we have race conditions, when we create jira issue,
    # got webhook about creation, but not yet save in database external_id with created
    # jira issue id. Which causes duplications
    RedmineBridge::WebhookJob.set(wait: 3.seconds).perform_later(integration, request.request_parameters)

    render json: {}
  end

  private

  def validate_params(integration, params)
    valid = RedmineBridge::Registry[integration.connector_id]
              .call(integration: integration)
              .valid_for?(params)
    send_airbrake_notification(integration.name, params) unless valid
    valid
  end

  def send_airbrake_notification(name, params)
    Airbrake.notify("Webhook wrong params for [#{name}]", params: params) if defined?(Airbrake) && Rails.env.production?
  end
end
