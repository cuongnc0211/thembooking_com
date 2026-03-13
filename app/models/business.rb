class Business < ApplicationRecord
  belongs_to :user
  has_many :branches, dependent: :destroy
  has_many :services, through: :branches
  has_many :bookings, through: :branches
  has_one_attached :logo

  # Constants
  BUSINESS_TYPES = %w[barber salon spa nail other]

  enum :business_type, BUSINESS_TYPES.zip(BUSINESS_TYPES).to_h

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :business_type, presence: true
  validates :user_id, uniqueness: { message: "already has a business" }
  validate :logo_format

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
