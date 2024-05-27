class UpdatesToExternalIssues < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    change_column_null :external_issues, :external_id, true
    change_column_null :external_issues, :external_url, true

    change_column_null :external_comments, :external_id, true
    change_column_null :external_comments, :external_url, true

    remove_index :external_comments, :redmine_id
    add_index :external_comments, :redmine_id, unique: true, where: 'redmine_id IS NOT NULL'
  end
end
