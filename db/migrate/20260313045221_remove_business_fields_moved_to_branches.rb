class RemoveBusinessFieldsMovedToBranches < ActiveRecord::Migration[8.1]
  def up
    # Remove migrated columns from businesses
    remove_column :businesses, :slug
    remove_column :businesses, :address
    remove_column :businesses, :phone
    remove_column :businesses, :operating_hours
    remove_column :businesses, :capacity

    # Remove old business_id FKs from child tables
    remove_reference :services, :business, foreign_key: true, index: true
    remove_reference :bookings, :business, foreign_key: true, index: true
    remove_reference :business_closures, :business, foreign_key: true, index: true
  end

  def down
    # Re-add columns to businesses
    add_column :businesses, :slug, :string
    add_column :businesses, :address, :string
    add_column :businesses, :phone, :string
    add_column :businesses, :operating_hours, :jsonb, default: {}
    add_column :businesses, :capacity, :integer, null: false, default: 1
    add_index :businesses, :slug, unique: true

    # Re-add business_id references
    add_reference :services, :business, null: true, foreign_key: true, index: true
    add_reference :bookings, :business, null: true, foreign_key: true, index: true
    add_reference :business_closures, :business, null: true, foreign_key: true, index: true

    # Restore business_id values from branches
    execute <<~SQL
      UPDATE services
      SET business_id = branches.business_id
      FROM branches
      WHERE services.branch_id = branches.id
    SQL

    execute <<~SQL
      UPDATE bookings
      SET business_id = branches.business_id
      FROM branches
      WHERE bookings.branch_id = branches.id
    SQL

    execute <<~SQL
      UPDATE business_closures
      SET business_id = branches.business_id
      FROM branches
      WHERE business_closures.branch_id = branches.id
    SQL

    # Restore businesses fields from their main branch
    execute <<~SQL
      UPDATE businesses
      SET slug = branches.slug,
          address = branches.address,
          phone = branches.phone,
          operating_hours = branches.operating_hours,
          capacity = branches.capacity
      FROM branches
      WHERE businesses.id = branches.business_id
        AND branches.name = 'Main Branch'
    SQL

    change_column_null :services, :business_id, false
    change_column_null :bookings, :business_id, false
    change_column_null :business_closures, :business_id, false
    change_column_null :businesses, :slug, false
  end
end
