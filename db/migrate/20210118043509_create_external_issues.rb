class CreateExternalIssues < ActiveRecord::Migration[5.2]
  def change
    create_table :external_issues do |t|
      t.belongs_to :redmine, foreign_key: { to_table: :issues }
      t.string :external_id, index: true, null: false
      t.string :external_url, null: false
      t.string :connector_id, null: false

      t.timestamps
    end
  end
end
