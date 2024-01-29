class AddColumnSouthbridgeIntegrationToBridgeIntegration < ActiveRecord::Migration[5.2]
  def change
    add_column :bridge_integrations, :southbridge_integration, :boolean, default: false
  end
end
