# frozen_string_literal: true

# Find integration and move to connector
class RedmineBridge::WebhookController < ActionController::API
  def create
    RedmineBridge::WebhookJob.perform_later(request.params)

    render json: {}
  end
end
