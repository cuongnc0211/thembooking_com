class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone, :string
    add_column :users, :bio, :text
    add_column :users, :time_zone, :string, default: "UTC"
    add_column :users, :profile_completed, :boolean, default: false
  end
end
