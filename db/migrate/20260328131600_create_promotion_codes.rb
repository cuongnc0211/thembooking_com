class CreatePromotionCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :promotion_codes do |t|
      t.string   :code,           null: false
      t.integer  :discount_type,  null: false, default: 0  # enum: percentage=0, fixed_amount=1
      t.decimal  :discount_value, null: false, precision: 10, scale: 2
      t.integer  :usage_limit                               # nil = unlimited
      t.integer  :used_count,     null: false, default: 0
      t.datetime :valid_from
      t.datetime :valid_until
      t.boolean  :active,         null: false, default: true
      t.text     :description

      t.timestamps
    end

    add_index :promotion_codes, :code, unique: true
    add_index :promotion_codes, :active
  end
end
