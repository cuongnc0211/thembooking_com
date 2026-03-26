class CreateStaffs < ActiveRecord::Migration[8.1]
  def change
    create_table :staffs do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.integer :role, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :staffs, :email_address, unique: true
    add_index :staffs, :role
    add_index :staffs, :active
  end
end
