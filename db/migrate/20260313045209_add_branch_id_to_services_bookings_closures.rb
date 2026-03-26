class AddBranchIdToServicesBookingsClosures < ActiveRecord::Migration[8.1]
  def change
    # Add nullable branch_id to services, bookings, business_closures
    add_reference :services, :branch, null: true, foreign_key: true, index: true
    add_reference :bookings, :branch, null: true, foreign_key: true, index: true
    add_reference :business_closures, :branch, null: true, foreign_key: true, index: true
  end
end
