class Business < ApplicationRecord
  belongs_to :user
  has_many :services, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_one_attached :logo

  # Constants
  WEEKDAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  enum :business_type, {
    barber: 0,
    salon: 1,
    spa: 2,
    nail: 3,
    other: 4
  }

  # Callbacks
  after_initialize :set_default_operating_hours, if: :need_init_operating_hours

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
  validate :operating_hours_format
  validate :operating_hours_logic
  validate :breaks_within_operating_hours
  validate :breaks_do_not_overlap

  # Normalize slug before validation
  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  def booking_url
    if Rails.env.development?
      "localhost:3000/#{slug}"
    else
      "thembooking.com/#{slug}"
    end
  end

  # Operating hours helper methods
  def open_on?(day_name)
    hours = operating_hours&.dig(day_name.to_s.downcase)
    return false unless hours
    !hours["closed"]
  end

  def hours_for(day_name)
    operating_hours&.dig(day_name.to_s.downcase)
  end

  def operating_on?(datetime)
    return false unless datetime

    day_name = datetime.strftime("%A").downcase
    hours = hours_for(day_name)
    return false unless hours && !hours["closed"]

    time_str = datetime.strftime("%H:%M")
    open_time = hours["open"]
    close_time = hours["close"]

    return false unless time_str >= open_time && time_str < close_time

    # Check if on break
    !on_break?(datetime)
  end

  def on_break?(datetime)
    return false unless datetime

    day_name = datetime.strftime("%A").downcase
    hours = hours_for(day_name)
    return false unless hours

    breaks = hours["breaks"] || []
    time_str = datetime.strftime("%H:%M")

    breaks.any? do |break_period|
      break_start = break_period["start"]
      break_end = break_period["end"]
      time_str >= break_start && time_str < break_end
    end
  end

  private

  def need_init_operating_hours
    operating_hours.blank?
  end

  def set_default_operating_hours
    return if operating_hours.present?

    self.operating_hours = {
      "monday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start": "12:00", "end": "13:00" }] },
      "tuesday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start": "12:00", "end": "13:00" }] },
      "wednesday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start": "12:00", "end": "13:00" }] },
      "thursday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start": "12:00", "end": "13:00" }] },
      "friday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start": "12:00", "end": "13:00" }] },
      "saturday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [{ "start": "12:00", "end": "13:00" }] },
      "sunday" => { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
    }
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

  def operating_hours_format
    return if operating_hours.blank?

    WEEKDAYS.each do |day|
      hours = operating_hours[day]
      next unless hours

      is_closed = hours["closed"]

      # Open days must have open and close times
      if !is_closed && hours["open"].blank?
        errors.add(:operating_hours, "#{day.capitalize} must have an opening time")
      end

      if !is_closed && hours["close"].blank?
        errors.add(:operating_hours, "#{day.capitalize} must have a closing time")
      end
    end
  end

  def operating_hours_logic
    return if operating_hours.blank?

    WEEKDAYS.each do |day|
      hours = operating_hours[day]
      next unless hours
      next if hours["closed"] # Skip validation for closed days

      open_time = hours["open"]
      close_time = hours["close"]

      next if open_time.blank? || close_time.blank?

      if close_time <= open_time
        errors.add(:operating_hours, "#{day.capitalize} closing time must be after opening time")
      end
    end
  end

  def breaks_within_operating_hours
    return if operating_hours.blank?

    WEEKDAYS.each do |day|
      hours = operating_hours[day]
      next unless hours
      next if hours["closed"]

      open_time = hours["open"]
      close_time = hours["close"]
      breaks = hours["breaks"] || []

      breaks.each do |break_period|
        break_start = break_period["start"]
        break_end = break_period["end"]

        next if break_start.blank? || break_end.blank?

        # Validate break end > break start
        if break_end <= break_start
          errors.add(:operating_hours, "#{day.capitalize} break end time must be after start time")
          next
        end

        # Validate break is within operating hours
        if break_start < open_time || break_end > close_time
          errors.add(:operating_hours, "#{day.capitalize} break must be within operating hours (#{open_time} - #{close_time})")
        end
      end
    end
  end

  def breaks_do_not_overlap
    return if operating_hours.blank?

    WEEKDAYS.each do |day|
      hours = operating_hours[day]
      next unless hours

      breaks = hours["breaks"] || []
      next if breaks.size < 2

      # Sort breaks by start time
      sorted_breaks = breaks.sort_by { |b| b["start"] }

      # Check for overlaps
      sorted_breaks.each_with_index do |break_period, index|
        next if index == sorted_breaks.size - 1

        current_end = break_period["end"]
        next_start = sorted_breaks[index + 1]["start"]

        if current_end > next_start
          errors.add(:operating_hours, "#{day.capitalize} has overlapping break times")
          break
        end
      end
    end
  end
end
