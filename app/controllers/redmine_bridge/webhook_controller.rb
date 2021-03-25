# frozen_string_literal: true

# Find integration and move to connector
class RedmineBridge::WebhookController < ActionController::API
  def create
    request.params[:key] = request.headers['Authorization']&.gsub(/^Bearer /, '') unless params[:key]

    RedmineBridge::WebhookJob.perform_later(request.params)

    render json: {}
  end
end
