class MakeBranchIdNonNullable < ActiveRecord::Migration[8.1]
  def up
    change_column_null :services, :branch_id, false
    change_column_null :bookings, :branch_id, false
    change_column_null :business_closures, :branch_id, false
  end

  def down
    change_column_null :services, :branch_id, true
    change_column_null :bookings, :branch_id, true
    change_column_null :business_closures, :branch_id, true
  end
end
