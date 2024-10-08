class AddOriginToComments < Rails.version < '5.0' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :external_comments, :origin, :string
  end
end
