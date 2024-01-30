class AddOnDeleteCascadeToIssueReference < ActiveRecord::Migration[5.2]
  def change
    remove_foreign_key :external_issues, :issues
    add_foreign_key :external_issues, :issues, column: :redmine_id, on_delete: :cascade
  end
end
