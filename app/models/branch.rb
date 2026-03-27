class Branch < ApplicationRecord
  belongs_to :business
  has_many :services, dependent: :destroy
  has_many :service_categories, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :business_closures, dependent: :destroy

  # Days of the week in order
  WEEKDAYS = %w[monday tuesday wednesday thursday friday saturday sunday].freeze

  # Set default operating hours on new unsaved records that have none
  after_initialize :set_default_operating_hours, if: :need_init_operating_hours

  # Validations
  validates :name, presence: true
  validates :capacity, presence: true,
                       numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 50 }
  validates :phone, format: { with: /\A[0-9\s\-\+\(\)]+\z/, message: "only allows numbers and basic formatting" },
                    allow_blank: true
  validate :operating_hours_format
  validate :operating_hours_logic
  validate :breaks_within_operating_hours
  validate :breaks_do_not_overlap

  # Normalize slug before validation
  normalizes :slug, with: ->(slug) { slug.strip.downcase }

  # Returns true if the branch is open on the given day name (e.g. "monday")
  def open_on?(day_name)
    hours = operating_hours&.dig(day_name.to_s.downcase)
    return false unless hours
    !hours["closed"]
  end

  # Returns the operating hours hash for a given day name
  def hours_for(day_name)
    operating_hours&.dig(day_name.to_s.downcase)
  end

  # Returns true if the branch is operating at the given datetime (not closed, not on break)
  def operating_on?(datetime)
    return false unless datetime

    day_name = datetime.strftime("%A").downcase
    hours = hours_for(day_name)
    return false unless hours && !hours["closed"]

    time_str = datetime.strftime("%H:%M")
    open_time = hours["open"]
    close_time = hours["close"]

    return false unless time_str >= open_time && time_str < close_time

    !on_break?(datetime)
  end

  # Returns true if the datetime falls within a break period for that day
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

  # Current number of in-progress bookings (used for capacity display)
  def current_capacity_usage
    bookings.where(status: :in_progress).count
  end

  # Capacity used as a percentage of total capacity
  def capacity_percentage
    return 0 if capacity.zero?
    (current_capacity_usage.to_f / capacity * 100).round
  end

  private

  def need_init_operating_hours
    operating_hours.blank?
  end

  # Seed a sensible default schedule (Mon–Sat 09:00–17:00, Sun closed)
  def set_default_operating_hours
    return if operating_hours.present?

    self.operating_hours = {
      "monday"    => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [ { "start" => "12:00", "end" => "13:00" } ] },
      "tuesday"   => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [ { "start" => "12:00", "end" => "13:00" } ] },
      "wednesday" => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [ { "start" => "12:00", "end" => "13:00" } ] },
      "thursday"  => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [ { "start" => "12:00", "end" => "13:00" } ] },
      "friday"    => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [ { "start" => "12:00", "end" => "13:00" } ] },
      "saturday"  => { "open" => "09:00", "close" => "17:00", "closed" => false, "breaks" => [ { "start" => "12:00", "end" => "13:00" } ] },
      "sunday"    => { "open" => nil, "close" => nil, "closed" => true, "breaks" => [] }
    }
  end

  # Each open day must have open and close times
  def operating_hours_format
    return if operating_hours.blank?

    WEEKDAYS.each do |day|
      hours = operating_hours[day]
      next unless hours

      is_closed = hours["closed"]

      if !is_closed && hours["open"].blank?
        errors.add(:operating_hours, "#{day.capitalize} must have an opening time")
      end

      if !is_closed && hours["close"].blank?
        errors.add(:operating_hours, "#{day.capitalize} must have a closing time")
      end
    end
  end

  # Closing time must be strictly after opening time for open days
  def operating_hours_logic
    return if operating_hours.blank?

    WEEKDAYS.each do |day|
      hours = operating_hours[day]
      next unless hours
      next if hours["closed"]

      open_time  = hours["open"]
      close_time = hours["close"]

      next if open_time.blank? || close_time.blank?

      if close_time <= open_time
        errors.add(:operating_hours, "#{day.capitalize} closing time must be after opening time")
      end
    end
  end

  # Each break must fall within the day's operating window
  def breaks_within_operating_hours
    return if operating_hours.blank?

    WEEKDAYS.each do |day|
      hours = operating_hours[day]
      next unless hours
      next if hours["closed"]

      open_time  = hours["open"]
      close_time = hours["close"]
      breaks     = hours["breaks"] || []

      breaks.each do |break_period|
        break_start = break_period["start"]
        break_end   = break_period["end"]

        next if break_start.blank? || break_end.blank?

        if break_end <= break_start
          errors.add(:operating_hours, "#{day.capitalize} break end time must be after start time")
          next
        end

        if break_start < open_time || break_end > close_time
          errors.add(:operating_hours, "#{day.capitalize} break must be within operating hours (#{open_time} - #{close_time})")
        end
      end
    end
  end

  # Breaks must not overlap each other
  def breaks_do_not_overlap
    return if operating_hours.blank?

    WEEKDAYS.each do |day|
      hours = operating_hours[day]
      next unless hours

      breaks = hours["breaks"] || []
      next if breaks.size < 2

      sorted_breaks = breaks.sort_by { |b| b["start"] }

      sorted_breaks.each_with_index do |break_period, index|
        next if index == sorted_breaks.size - 1

        current_end = break_period["end"]
        next_start  = sorted_breaks[index + 1]["start"]

        if current_end > next_start
          errors.add(:operating_hours, "#{day.capitalize} has overlapping break times")
          break
        end
      end
    end
  end
end
