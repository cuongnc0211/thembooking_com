class CreateBookingServices < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_services do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true

      t.timestamps
    end

    add_index :booking_services, [:booking_id, :service_id], unique: true
  end
end
