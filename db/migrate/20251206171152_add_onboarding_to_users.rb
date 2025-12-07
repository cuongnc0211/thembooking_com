class AddOnboardingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarding_step, :integer, default: 1, null: false
    add_column :users, :onboarding_completed_at, :datetime

    add_index :users, :onboarding_step
    add_index :users, :onboarding_completed_at
  end
end
