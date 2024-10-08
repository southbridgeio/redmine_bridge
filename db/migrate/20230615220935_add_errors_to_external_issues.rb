class AddErrorsToExternalIssues < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :external_issues, :sync_errors, :jsonb, default: {}
    add_column :external_comments, :sync_errors, :jsonb, default: {}

    add_reference :external_issues, :bridge_integration, foreign_key: { to_table: :bridge_integrations }
  end
end
