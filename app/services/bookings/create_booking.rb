module Bookings
  class CreateBooking
    # Support both old Result struct and new hash return format
    Result = Struct.new(:success?, :booking, :error)

    def initialize(business:, service_ids:, start_time: nil, scheduled_at: nil, customer_params:)
      @business = business
      @service_ids = Array(service_ids)
      # Support both parameter names and ensure it's a Time object
      raw_time = start_time || scheduled_at
      @start_time = raw_time.is_a?(String) ? Time.zone.parse(raw_time) : raw_time
      @customer_params = customer_params
    end

    def call
      # Return hash format for new slot-based approach
      return { success: false, booking: nil, error: "Services must be provided" } if @service_ids.empty?

      # Validate services belong to business
      services = @business.services.where(id: @service_ids)
      if services.count != @service_ids.count
        return { success: false, booking: nil, error: "One or more services do not belong to this business" }
      end

      # Calculate total duration and find required slots
      total_duration = services.sum(:duration_minutes)
      required_slots = find_required_slots(total_duration)

      if required_slots.empty?
        return { success: false, booking: nil, error: "Time slot no longer available. Please select another time." }
      end

      # Create booking with slot-based transaction
      booking = nil
      ActiveRecord::Base.transaction do
        # Lock slots with FOR UPDATE to prevent race conditions
        locked_slots = Slot.where(id: required_slots.map(&:id))
                           .lock("FOR UPDATE")
                           .order(:start_time)
                           .to_a

        # Verify all slots still have capacity
        unless all_slots_available?(locked_slots)
          raise ActiveRecord::Rollback
        end

        # Create booking
        booking = @business.bookings.new(@customer_params)
        booking.scheduled_at = @start_time # Set for backwards compatibility
        booking.status = :pending
        booking.source = :online
        booking.services = services

        # Validate booking
        unless booking.valid?
          raise ActiveRecord::Rollback
        end

        # Save booking
        booking.save!

        # Link slots and decrement capacity
        locked_slots.each do |slot|
          BookingSlot.create!(booking: booking, slot: slot)
          slot.decrement!(:capacity)
        end
      end

      if booking&.persisted?
        { success: true, booking: booking, error: nil }
      else
        error_message = booking&.errors&.full_messages&.join(", ") || "Time slot no longer available. Please select another time."
        { success: false, booking: nil, error: error_message }
      end
    rescue ActiveRecord::RecordInvalid => e
      { success: false, booking: nil, error: e.message }
    end

    private

    def find_required_slots(total_duration_minutes)
      slots_needed = (total_duration_minutes / 15.0).ceil
      end_time = @start_time + total_duration_minutes.minutes

      @business.slots
        .where("start_time >= ? AND start_time < ?", @start_time, end_time)
        .order(:start_time)
        .to_a
    end

    def all_slots_available?(slots)
      return false if slots.empty?

      # Check all slots have capacity
      return false unless slots.all? { |slot| slot.capacity > 0 }

      # Check slots are consecutive (no gaps)
      slots.each_cons(2).all? do |slot1, slot2|
        slot2.start_time == slot1.end_time
      end
    end
  end
end
