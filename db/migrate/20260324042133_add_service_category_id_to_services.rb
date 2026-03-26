class AddServiceCategoryIdToServices < ActiveRecord::Migration[8.1]
  def change
    add_reference :services, :service_category, null: true, foreign_key: true
  end
end
