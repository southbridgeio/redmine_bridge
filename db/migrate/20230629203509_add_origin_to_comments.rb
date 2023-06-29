class AddOriginToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :external_comments, :origin, :string
  end
end
