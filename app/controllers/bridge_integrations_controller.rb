# frozen_string_literal: true

# Configure integrations
class BridgeIntegrationsController < ApplicationController
  layout 'admin'

  def create
    @bridge_integration = ::BridgeIntegration.new(strong_params)

    if @bridge_integration.save
      redirect_to '/settings/plugin/redmine_bridge'
    else
      render :new
    end
  end

  def update
    @bridge_integration = ::BridgeIntegration.find(params[:id])

    if @bridge_integration.update(strong_params)
      redirect_to '/settings/plugin/redmine_bridge'
    else
      render :edit
    end
  end

  def new
    @bridge_integration = ::BridgeIntegration.new
  end

  def edit
    @bridge_integration = ::BridgeIntegration.find(params[:id])
  end

  def destroy
    @bridge_integration = ::BridgeIntegration.find(params[:id])

    if @bridge_integration.destroy
      redirect_to '/settings/plugin/redmine_bridge', notice: 'Succesfull deleted'
    else
      redirect_to '/settings/plugin/redmine_bridge', notice: 'Something went wrong'
    end
  end

  private

  def strong_params
    params.require(:bridge_integration).permit(
      :name,
      :key,
      :connector_id,
      :project_id,
      settings: %i[redmine_status_id connector_status_id redmine_priority_id connector_priority_id]
    )
  end
end
