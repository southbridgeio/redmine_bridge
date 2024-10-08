class AddOnDeleteCascadeToIssueReference < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :external_issues, :issues
    add_foreign_key :external_issues, :issues, column: :redmine_id, on_delete: :cascade
  end
end
