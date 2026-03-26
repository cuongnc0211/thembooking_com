class CreateBranches < ActiveRecord::Migration[8.1]
  def change
    create_table :branches do |t|
      t.references :business, null: false, foreign_key: true, index: true
      t.string :name, null: false, default: "Main Branch"
      t.string :slug, null: false
      t.string :address
      t.string :phone
      t.jsonb :operating_hours, default: {}
      t.integer :capacity, null: false, default: 1
      t.boolean :active, null: false, default: true
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :branches, :slug, unique: true
    add_index :branches, [ :business_id, :active ]
  end
end
