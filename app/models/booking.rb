class Booking < ApplicationRecord
  belongs_to :business
  has_many :booking_services, dependent: :destroy
  has_many :services, through: :booking_services
  has_many :booking_slots, dependent: :destroy
  has_many :slots, through: :booking_slots

  # Turbo Streams - Broadcast changes to business-specific stream
  after_create_commit :broadcast_booking_created
  after_update_commit :broadcast_booking_updated
  after_destroy_commit :broadcast_booking_destroyed

  # Enums
  enum :status, {
    pending: 0,
    confirmed: 1,
    in_progress: 2,
    completed: 3,
    cancelled: 4,
    no_show: 5
  }

  enum :source, {
    online: 0,
    walk_in: 1
  }

  # Validations
  validates :customer_name, presence: true
  validates :customer_phone, presence: true
  validates :scheduled_at, presence: true
  validate :customer_phone_format
  validate :customer_email_format, if: -> { customer_email.present? }
  validate :scheduled_at_in_future, if: -> { scheduled_at.present? && online? && !skip_future_validation }
  validate :must_have_at_least_one_service

  attr_accessor :skip_future_validation

  # Scopes
  scope :active, -> { where(status: [:confirmed, :in_progress]) }
  scope :for_date, ->(date) { where("DATE(scheduled_at) = ?", date) }
  scope :by_time, -> { order(scheduled_at: :asc) }
  scope :overlapping, ->(start_time, end_time) {
    joins(:booking_services, :services)
      .group("bookings.id")
      .having(
        "bookings.scheduled_at < ? AND " \
        "bookings.scheduled_at + (SUM(services.duration_minutes) || ' minutes')::interval > ?",
        end_time, start_time
      )
  }

  # Methods
  def total_duration_minutes
    services.sum(:duration_minutes)
  end

  def end_time
    scheduled_at + total_duration_minutes.minutes
  end

  private

  def customer_phone_format
    return if customer_phone.blank?

    unless customer_phone.match?(/\A0\d{9}\z/)
      errors.add(:customer_phone, "must be a valid Vietnam phone number (10 digits starting with 0)")
    end
  end

  def customer_email_format
    return if customer_email.blank?

    unless customer_email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      errors.add(:customer_email, "is not a valid email address")
    end
  end

  def scheduled_at_in_future
    return if scheduled_at.blank?

    if scheduled_at < Time.current
      errors.add(:scheduled_at, "must be in the future")
    end
  end

  def must_have_at_least_one_service
    if services.empty?
      errors.add(:services, "must have at least one service")
    end
  end

  def broadcast_booking_created
    broadcast_refresh_to_business
  end

  def broadcast_booking_updated
    broadcast_refresh_to_business
  end

  def broadcast_booking_destroyed
    broadcast_refresh_to_business
  end

  def broadcast_refresh_to_business
    # Broadcast a page refresh to all clients watching this business's bookings
    # This ensures capacity indicators and booking lists stay in sync
    broadcast_refresh_to "business_#{business_id}_bookings"
  end
end
