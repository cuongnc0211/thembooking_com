class ServiceCategory < ApplicationRecord
  belongs_to :branch
  # Nullify category on services when category is deleted (don't cascade-delete services)
  has_many :services, foreign_key: :service_category_id, dependent: :nullify

  validates :name, presence: true,
                   length: { maximum: 100 },
                   uniqueness: { scope: :branch_id, case_sensitive: false }
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :name) }
end
