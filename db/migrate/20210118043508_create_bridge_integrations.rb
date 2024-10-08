class CreateBridgeIntegrations < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :bridge_integrations do |t|
      t.string :name, null: false
      t.string :key, null: false
      t.string :connector_id, null: false
      t.references :project, foreign_key: true, index: true
      t.json :settings, default: {}

      t.timestamps
    end
  end
end
