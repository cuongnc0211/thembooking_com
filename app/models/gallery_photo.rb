class GalleryPhoto < ApplicationRecord
  belongs_to :business
  has_one_attached :image

  validates :image, presence: true
  validates :caption, length: { maximum: 200 }, allow_blank: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :image_format
  validate :max_photos_per_business, on: :create

  # Default ordering: by position ascending, then creation time
  scope :ordered, -> { order(:position, :created_at) }

  private

  def image_format
    return unless image.attached?

    unless image.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:image, "must be JPEG, PNG, or WebP")
    end

    if image.byte_size > 10.megabytes
      errors.add(:image, "must be less than 10MB")
    end
  end

  def max_photos_per_business
    return unless business

    if business.gallery_photos.count >= 20
      errors.add(:base, "Maximum 20 gallery photos allowed per business")
    end
  end
end
