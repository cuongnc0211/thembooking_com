class CreateServiceCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :service_categories do |t|
      t.references :branch, null: false, foreign_key: true
      t.string :name, null: false, limit: 100
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :service_categories, [ :branch_id, :name ], unique: true
  end
end
