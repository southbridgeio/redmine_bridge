class AddDefaultProjectToBridgeIntegration < ActiveRecord::Migration[5.2]
  def change
    add_reference :bridge_integrations, :default_project,
                  foreign_key: { to_table: :projects }, index: true, null: true, default: nil
  end
end
