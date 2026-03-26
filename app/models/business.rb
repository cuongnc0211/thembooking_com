class Business < ApplicationRecord
  belongs_to :user
  has_many :branches, dependent: :destroy
  has_many :services, through: :branches
  has_many :bookings, through: :branches
  has_many :gallery_photos, dependent: :destroy
  has_one_attached :logo
  has_one_attached :cover_photo

  # Constants
  BUSINESS_TYPES = %w[barber salon spa nail other]

  enum :business_type, BUSINESS_TYPES.zip(BUSINESS_TYPES).to_h

  # Auto-generate slug from name before validation if not set
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  normalizes :slug, with: ->(s) { s.strip.downcase }

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :business_type, presence: true
  validates :user_id, uniqueness: { message: "already has a business" }
  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9\-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" },
                   length: { minimum: 3, maximum: 50 },
                   slug_uniqueness: true
  validates :headline, length: { maximum: 200 }, allow_blank: true
  validates :theme_color, format: { with: /\A#[0-9a-fA-F]{6}\z/ }, allow_blank: true
  validate :logo_format
  validate :cover_photo_format

  private

  # Auto-generates a slug from name, appending a counter suffix to resolve collisions.
  def generate_slug
    base = name.parameterize.first(50)
    candidate = base
    counter = 1
    while Business.where(slug: candidate).exists? || Branch.where(slug: candidate).exists?
      candidate = "#{base.first(46)}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end

  def logo_format
    return unless logo.attached?

    unless logo.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:logo, "must be a JPEG, PNG, GIF, or WebP")
    end

    if logo.byte_size > 5.megabytes
      errors.add(:logo, "size must be less than 5MB")
    end
  end

  def cover_photo_format
    return unless cover_photo.attached?

    unless cover_photo.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:cover_photo, "must be a JPEG, PNG, or WebP")
    end

    if cover_photo.byte_size > 10.megabytes
      errors.add(:cover_photo, "size must be less than 10MB")
    end
  end
end
