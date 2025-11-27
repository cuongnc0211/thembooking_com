class Service < ApplicationRecord
  belongs_to :business

  # Money integration
  monetize :price_cents, with_model_currency: :currency

  # Scopes
  scope :active, -> { where(active: true) }

  # Validations
  validates :name, presence: true,
                   length: { maximum: 100 },
                   uniqueness: { scope: :business_id, case_sensitive: false }

  validates :duration_minutes, presence: true,
                               inclusion: { in: [ 15, 30, 45, 60, 90, 120 ] }

  validates :price_cents, presence: true,
                          numericality: { only_integer: true, greater_than: 0 }
end
