class Service < ApplicationRecord
  belongs_to :business

  # Duration options in minutes
  DURATION_OPTIONS = [
    { value: 15, label: "15 min" },
    { value: 30, label: "30 min" },
    { value: 45, label: "45 min" },
    { value: 60, label: "1 hour" },
    { value: 90, label: "1.5 hours" },
    { value: 120, label: "2 hours" }
  ].freeze

  # Helper method for select options
  def self.duration_options_for_select
    DURATION_OPTIONS.map { |opt| [ opt[:label], opt[:value] ] }
  end

  # Money integration
  monetize :price_cents, with_model_currency: :currency

  # Scopes
  scope :active, -> { where(active: true) }

  # Validations
  validates :name, presence: true,
                   length: { maximum: 100 },
                   uniqueness: { scope: :business_id, case_sensitive: false }

  # validates :duration_minutes, presence: true,
  #                              inclusion: { in: DURATION_OPTIONS.map { |o| o[:value] } }

  validates :price_cents, presence: true,
                          numericality: { only_integer: true, greater_than: 0 }
end
