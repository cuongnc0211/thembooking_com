class Business < ApplicationRecord
  belongs_to :user
  has_one_attached :logo

  enum :business_type, {
    barber: 0,
    salon: 1,
    spa: 2,
    nail: 3,
    other: 4
  }

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9\-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" },
                   length: { minimum: 3, maximum: 50 }
  validates :business_type, presence: true
  validates :capacity, presence: true,
                       numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 50 }
  validates :phone, format: { with: /\A[0-9\s\-\+\(\)]+\z/, message: "only allows numbers and basic formatting" },
                    allow_blank: true
  validates :user_id, uniqueness: { message: "already has a business" }
  validate :logo_format

  # Normalize slug before validation
  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  def booking_url
    "#{slug}.thembooking.com"
  end

  private

  def logo_format
    return unless logo.attached?

    unless logo.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:logo, "must be a JPEG, PNG, GIF, or WebP")
    end

    if logo.byte_size > 5.megabytes
      errors.add(:logo, "size must be less than 5MB")
    end
  end
end
