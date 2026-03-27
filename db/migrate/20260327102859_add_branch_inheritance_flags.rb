class AddBranchInheritanceFlags < ActiveRecord::Migration[8.1]
  def change
    add_column :branches, :is_main, :boolean, default: false, null: false
    add_column :branches, :inherit_from_main, :boolean, default: false, null: false

    # Mark the first (oldest) branch per business as the main branch
    reversible do |dir|
      dir.up do
        Business.find_each do |business|
          business.branches.order(:created_at).first&.update_columns(is_main: true)
        end
      end
    end
  end
end
