module Bookings
  class CheckAvailability
    AVAILABILITY_STEP = 15.minutes
    ACTIVE_STATUSES = %w[pending confirmed in_progress].freeze

    def initialize(branch:, service: nil, service_ids: nil, date:)
      @branch = branch
      @service = service
      @service_ids = service_ids ? Array(service_ids) : nil
      @date = date.is_a?(String) ? Date.parse(date) : date
    end

    def call
      return [] if business_closed_on_date?

      day_hours = operating_hours_for_date
      return [] if day_hours.nil? || day_hours["closed"]

      total_duration = calculate_total_duration
      return [] if total_duration.zero?

      candidates = generate_candidate_times(day_hours, total_duration)
      candidates.select { |start_time| available_at?(start_time, total_duration) }
    end

    private

    def business_closed_on_date?
      @branch.business_closures.exists?(date: @date)
    end

    def operating_hours_for_date
      day_name = @date.strftime("%A").downcase
      @branch.effective_operating_hours&.dig(day_name)
    end

    def calculate_total_duration
      if @service
        @service.duration_minutes
      elsif @service_ids.present?
        Service.where(id: @service_ids, branch: @branch).sum(:duration_minutes)
      else
        0
      end
    end

    # Generate all candidate start times within operating hours, excluding breaks
    def generate_candidate_times(hours, duration_minutes)
      open_time  = parse_time_on_date(hours["open"])
      close_time = parse_time_on_date(hours["close"])
      breaks     = parse_breaks(hours["breaks"] || [])

      candidates = []
      # For today, skip slots that have already started
      earliest = @date == Date.current ? [ open_time, Time.current ].max : open_time
      # Round up to the next 15-min boundary so we don't show a slot mid-way through
      if earliest > open_time
        remainder = earliest.min % AVAILABILITY_STEP.in_minutes
        earliest += (AVAILABILITY_STEP.in_minutes - remainder).minutes if remainder > 0
      end
      current = earliest

      # Stop when the booking would extend past closing time
      while current + duration_minutes.minutes <= close_time
        candidates << current unless during_any_break?(current, duration_minutes, breaks)
        current += AVAILABILITY_STEP
      end

      candidates
    end

    # Returns true if the time window [start, start+duration) overlaps any break
    def during_any_break?(start_time, duration_minutes, breaks)
      end_time = start_time + duration_minutes.minutes
      breaks.any? do |b|
        # Overlap: start < break_end AND end > break_start
        start_time < b[:end] && end_time > b[:start]
      end
    end

    # Check if business has capacity at candidate start_time
    def available_at?(start_time, duration_minutes)
      end_time = start_time + duration_minutes.minutes

      overlap_count = @branch.bookings
        .where(status: ACTIVE_STATUSES)
        .where("scheduled_at < ? AND end_time > ?", end_time, start_time)
        .count

      overlap_count < @branch.capacity
    end

    def parse_time_on_date(time_str)
      Time.zone.parse("#{@date} #{time_str}")
    end

    def parse_breaks(breaks_array)
      breaks_array.map do |b|
        {
          start: parse_time_on_date(b["start"]),
          end:   parse_time_on_date(b["end"])
        }
      end
    end
  end
end
