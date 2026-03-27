class CreateBusinessClosures < ActiveRecord::Migration[8.1]
  def change
    create_table :business_closures do |t|
      t.references :business, null: false, foreign_key: true
      t.date :date, null: false
      t.string :reason, limit: 255

      t.timestamps
    end

    add_index :business_closures, [ :business_id, :date ], unique: true
  end
end
