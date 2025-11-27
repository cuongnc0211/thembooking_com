module Bookings
  class CheckAvailability
    def initialize(business:, service_ids:, date:)
      @business = business
      @service_ids = Array(service_ids)
      @date = date
    end

    def call
      return [] if @service_ids.empty?
      return [] unless operating_hours

      available_slots
    end

    private

    def available_slots
      slots = []
      current_time = slot_start_time

      while current_time <= slot_end_time
        if slot_available?(current_time)
          slots << current_time.strftime("%H:%M")
        end
        current_time += 15.minutes
      end

      slots
    end

    def slot_available?(slot_start)
      slot_end = slot_start + total_duration.minutes

      # Check if slot is in the past
      return false if slot_start < Time.current

      # Check if slot extends past closing time
      return false if slot_end > closing_time

      # Check if slot overlaps with break time
      return false if overlaps_with_break?(slot_start, slot_end)

      # Check capacity
      overlapping_count = count_overlapping_bookings(slot_start, slot_end)
      overlapping_count < @business.capacity
    end

    def overlaps_with_break?(slot_start, slot_end)
      return false unless break_start && break_end

      # Booking overlaps with break if:
      # - booking starts before break ends AND
      # - booking ends after break starts
      slot_start < break_end && slot_end > break_start
    end

    def count_overlapping_bookings(slot_start, slot_end)
      @business.bookings
        .active
        .overlapping(slot_start, slot_end)
        .count
        .size
    end

    def total_duration
      @total_duration ||= Service.where(id: @service_ids).sum(:duration_minutes)
    end

    def operating_hours
      @operating_hours ||= begin
        day_name = @date.strftime("%A").downcase
        hours = @business.operating_hours[day_name]
        hours if hours && !hours["closed"]
      end
    end

    def opening_time
      @opening_time ||= begin
        return nil unless operating_hours
        time_str = operating_hours["open"]
        Time.zone.parse("#{@date} #{time_str}")
      end
    end

    def closing_time
      @closing_time ||= begin
        return nil unless operating_hours
        time_str = operating_hours["close"]
        Time.zone.parse("#{@date} #{time_str}")
      end
    end

    def break_start
      @break_start ||= begin
        return nil unless operating_hours && operating_hours["break_start"]
        time_str = operating_hours["break_start"]
        Time.zone.parse("#{@date} #{time_str}")
      end
    end

    def break_end
      @break_end ||= begin
        return nil unless operating_hours && operating_hours["break_end"]
        time_str = operating_hours["break_end"]
        Time.zone.parse("#{@date} #{time_str}")
      end
    end

    def slot_start_time
      # Start from opening time, or current time if checking today
      [opening_time, Time.current].max
    end

    def slot_end_time
      # End time is closing time minus service duration
      closing_time - total_duration.minutes
    end
  end
end
