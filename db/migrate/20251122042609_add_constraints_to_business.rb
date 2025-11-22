class AddConstraintsToBusiness < ActiveRecord::Migration[8.1]
  def change
    # Add NOT NULL constraints
    change_column_null :businesses, :name, false
    change_column_null :businesses, :slug, false
    change_column_null :businesses, :capacity, false
    change_column_null :businesses, :business_type, false

    # Add default values
    change_column_default :businesses, :business_type, from: nil, to: 0
    change_column_default :businesses, :capacity, from: nil, to: 1
    change_column_default :businesses, :operating_hours, from: nil, to: {}
    change_column_default :businesses, :landing_page_config, from: nil, to: {}

    # One business per user in MVP (unique index)
    add_index :businesses, :user_id, unique: true, name: 'index_businesses_on_user_id_unique'
  end
end
