class CreateBookingSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_slots do |t|
      t.references :booking, null: false, foreign_key: true, index: true
      t.references :slot, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :booking_slots, [ :booking_id, :slot_id ], unique: true, name: "index_booking_slots_on_booking_and_slot"
  end
end
