class CreateSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :slots do |t|
      t.references :business, null: false, foreign_key: true, index: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.date :date, null: false, index: true
      t.integer :capacity, null: false, default: 0
      t.integer :original_capacity, null: false, default: 0

      t.timestamps
    end

    add_index :slots, [ :business_id, :start_time ], unique: true, name: "index_slots_on_business_and_start_time"
    add_index :slots, [ :business_id, :date ], name: "index_slots_on_business_and_date"
  end
end
