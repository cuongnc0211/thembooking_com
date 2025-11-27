class RemoveServiceIdFromBookings < ActiveRecord::Migration[8.1]
  def change
    remove_reference :bookings, :service, null: false, foreign_key: true
  end
end
