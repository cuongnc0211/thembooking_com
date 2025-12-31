class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :business, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.string :customer_name, null: false, limit: 100
      t.string :customer_email, limit: 255
      t.string :customer_phone, null: false, limit: 20
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0, null: false
      t.integer :source, default: 0, null: false
      t.text :notes
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    # Add indexes for common queries
    add_index :bookings, [ :business_id, :scheduled_at ]
    add_index :bookings, [ :business_id, :status ]
    add_index :bookings, :customer_email
    add_index :bookings, :customer_phone
  end
end
