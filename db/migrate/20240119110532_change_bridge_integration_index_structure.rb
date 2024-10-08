class ChangeBridgeIntegrationIndexStructure < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    remove_index :bridge_integrations, name: 'index_bridge_integrations_on_key'
    add_index :bridge_integrations, %i[key project_id], unique: true
  end
end
