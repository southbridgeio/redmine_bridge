# frozen_string_literal: true

# Find integration and move to connector
class RedmineBridge::WebhookController < ActionController::API
  before_action :verify_integration

  def create
    # wait 3 seconds - because we have race conditions, when we create jira issue,
    # got webhook about creation, but not yet save in database external_id with created
    # jira issue id. Which causes duplications
    RedmineBridge::WebhookJob.set(wait: 3.seconds).perform_later(integration, request.request_parameters)

    render json: {}
  end

  def operational_check
    result = RedmineBridge::WebhookJob.perform_now(integration, request.request_parameters, test: true)

    if result.present? && result.all?(&:valid?)
      render json: {}, status: :ok
    else
      render json: { errors_info: errors_info(result) }, status: :unprocessable_entity
    end
  end

  private

  attr_accessor :key

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

  def verify_integration
    self.key = params[:key] || request.headers['X-Gitlab-Token'] || request.headers['Authorization']&.gsub(/^Bearer /, '')

    head :forbidden if !integration || !validate_params(integration, request.request_parameters)
  end

  def integration
    @integration ||= BridgeIntegration.find_by(key: key)
  end

  def errors_info(issues)
    return [{ alert: nil, errors: ["Issues can't be created"] }] if issues.blank?

    issues.map do |issue|
      issue.validate

      {
        alert: issue.description,
        errors: issue.errors.full_messages
      }
    end
  end
end
