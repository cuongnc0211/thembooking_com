class CreateBusinesses < ActiveRecord::Migration[8.1]
  def change
    create_table :businesses do |t|
      t.string :name
      t.string :business_type
      t.text :description
      t.string :address
      t.string :phone
      t.string :slug
      t.integer :capacity
      t.jsonb :operating_hours
      t.jsonb :landing_page_config
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :businesses, :slug, unique: true
  end
end
