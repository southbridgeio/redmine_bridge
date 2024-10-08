class RevertBridgeIntegrationIndexStructure < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    remove_index :bridge_integrations, name: 'index_bridge_integrations_on_key_and_project_id'
    add_index :bridge_integrations, :key, unique: true
  end
end
