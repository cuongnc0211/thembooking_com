class MigrateBusinessDataToBranches < ActiveRecord::Migration[8.1]
  # Reversible data migration: for each business, create a main branch
  # copying slug, address, phone, operating_hours, capacity then re-point
  # services/bookings/business_closures to the new branch.
  def up
    ActiveRecord::Base.transaction do
      execute <<~SQL
        INSERT INTO branches (business_id, name, slug, address, phone, operating_hours, capacity, active, position, created_at, updated_at)
        SELECT id, 'Main Branch', slug, address, phone, operating_hours, capacity, true, 0, NOW(), NOW()
        FROM businesses
      SQL

      # Update services to point to the corresponding main branch
      execute <<~SQL
        UPDATE services
        SET branch_id = branches.id
        FROM branches
        WHERE services.business_id = branches.business_id
      SQL

      # Update bookings to point to the corresponding main branch
      execute <<~SQL
        UPDATE bookings
        SET branch_id = branches.id
        FROM branches
        WHERE bookings.business_id = branches.business_id
      SQL

      # Update business_closures to point to the corresponding main branch
      execute <<~SQL
        UPDATE business_closures
        SET branch_id = branches.id
        FROM branches
        WHERE business_closures.business_id = branches.business_id
      SQL
    end
  end

  def down
    # Clear branch_id from child tables first
    execute "UPDATE services SET branch_id = NULL"
    execute "UPDATE bookings SET branch_id = NULL"
    execute "UPDATE business_closures SET branch_id = NULL"

    # Remove all auto-created main branches
    execute "DELETE FROM branches WHERE name = 'Main Branch'"
  end
end
