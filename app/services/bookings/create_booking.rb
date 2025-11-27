module Bookings
  class CreateBooking
    Result = Struct.new(:success?, :booking, :error)

    def initialize(business:, service_ids:, scheduled_at:, customer_params:)
      @business = business
      @service_ids = Array(service_ids)
      @scheduled_at = scheduled_at
      @customer_params = customer_params
    end

    def call
      return Result.new(false, nil, "Services must be provided") if @service_ids.empty?

      # Validate services belong to business
      services = @business.services.where(id: @service_ids)
      if services.count != @service_ids.count
        return Result.new(false, nil, "One or more services do not belong to this business")
      end

      booking = @business.bookings.new(@customer_params)
      booking.scheduled_at = @scheduled_at
      booking.status = :pending
      booking.source = :online

      # Use transaction to ensure atomicity
      ActiveRecord::Base.transaction do
        # Lock business to prevent race conditions
        @business.lock!

        # Add services to booking
        booking.services = services

        # Validate booking (this will check if services are present)
        unless booking.valid?
          raise ActiveRecord::Rollback
        end

        # Re-check availability before saving
        unless slot_available?(booking)
          booking.errors.add(:base, "This time slot is no longer available. Please select another time.")
          raise ActiveRecord::Rollback
        end

        # Save booking
        booking.save!
      end

      if booking.persisted?
        Result.new(true, booking, nil)
      else
        Result.new(false, nil, booking.errors.full_messages.join(", "))
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(false, nil, e.message)
    end

    private

    def slot_available?(booking)
      total_duration = booking.total_duration_minutes
      slot_end = booking.scheduled_at + total_duration.minutes

      # Count overlapping active bookings (excluding current booking if updating)
      overlapping_count = @business.bookings
        .active
        .overlapping(booking.scheduled_at, slot_end)
        .where.not(id: booking.id)
        .count
        .size

      overlapping_count < @business.capacity
    end
  end
end
