class CreateExternalComments < ActiveRecord::Migration[5.2]
  def change
    create_table :external_comments do |t|
      t.belongs_to :redmine, foreign_key: { to_table: :journals }
      t.belongs_to :external_issue, foreign_key: { to_table: :external_issues }
      t.belongs_to :bridge_integration, foreign_key: { to_table: :bridge_integrations }
      t.string :external_id, index: true, null: false
      t.string :external_url, null: false
      t.string :connector_id, null: false
      t.string :state

      t.timestamps
    end

    add_column :external_issues, :state, :string
  end
end
