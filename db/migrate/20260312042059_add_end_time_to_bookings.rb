class AddEndTimeToBookings < ActiveRecord::Migration[8.1]
  def up
    add_column :bookings, :end_time, :datetime

    # Backfill: compute end_time = scheduled_at + sum of booked services duration
    execute <<~SQL
      UPDATE bookings b
      SET end_time = b.scheduled_at + (
        SELECT INTERVAL '1 minute' * COALESCE(SUM(s.duration_minutes), 0)
        FROM booking_services bs
        JOIN services s ON s.id = bs.service_id
        WHERE bs.booking_id = b.id
      )
      WHERE b.scheduled_at IS NOT NULL
    SQL

    # Fallback: bookings with no services (duration = 0 gives scheduled_at, not null) or null scheduled_at
    execute "UPDATE bookings SET end_time = scheduled_at + INTERVAL '30 minutes' WHERE end_time IS NULL"

    change_column_null :bookings, :end_time, false
    add_index :bookings, [ :business_id, :scheduled_at, :end_time ], name: 'idx_bookings_overlap_check'
  end

  def down
    remove_index :bookings, name: 'idx_bookings_overlap_check'
    remove_column :bookings, :end_time
  end
end
