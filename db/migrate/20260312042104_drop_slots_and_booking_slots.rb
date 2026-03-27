class DropSlotsAndBookingSlots < ActiveRecord::Migration[8.1]
  def up
    # Drop booking_slots first (has FK referencing slots)
    drop_table :booking_slots
    drop_table :slots
  end

  def down
    # Recreate slots
    create_table :slots do |t|
      t.references :business, null: false, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.date :date, null: false
      t.integer :capacity, default: 0, null: false
      t.integer :original_capacity, default: 0, null: false
      t.timestamps
    end
    add_index :slots, [ :business_id, :start_time ], unique: true, name: 'index_slots_on_business_and_start_time'
    add_index :slots, [ :business_id, :date ], name: 'index_slots_on_business_and_date'
    add_index :slots, :date, name: 'index_slots_on_date'

    # Recreate booking_slots
    create_table :booking_slots do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :slot, null: false, foreign_key: true
      t.timestamps
    end
    add_index :booking_slots, [ :booking_id, :slot_id ], unique: true, name: 'index_booking_slots_on_booking_and_slot'
  end
end
