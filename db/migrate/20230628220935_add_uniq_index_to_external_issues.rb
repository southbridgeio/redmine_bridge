class AddUniqIndexToExternalIssues < ActiveRecord::Migration[5.2]
  def change
    remove_index :external_issues, :redmine_id
    add_index :external_issues, [:redmine_id, :connector_id], unique: true, where: 'redmine_id IS NOT NULL'
    add_index :external_issues, [:redmine_id, :bridge_integration_id], unique: true, where: 'bridge_integration_id IS NOT NULL'
    add_index :external_issues, [:external_id, :bridge_integration_id], unique: true, where: 'bridge_integration_id IS NOT NULL'

    remove_index :external_comments, :redmine_id
    add_index :external_comments, [:redmine_id, :connector_id], unique: true, where: 'redmine_id IS NOT NULL'
    add_index :external_comments, [:redmine_id, :bridge_integration_id],
      unique: true, where: 'bridge_integration_id IS NOT NULL',
      name: 'index_external_comments_on_redmine_id_and_integration_id'
    add_index :external_comments, [:external_id, :bridge_integration_id],
      unique: true, where: 'bridge_integration_id IS NOT NULL',
      name: 'index_external_comments_on_external_id_and_integration_id'

    add_index :bridge_integrations, :key, unique: true
  end
end
