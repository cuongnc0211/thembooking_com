module Bookings
  class CreateBooking
    def initialize(business:, service_ids:, start_time: nil, scheduled_at: nil, customer_params:)
      @business = business
      @service_ids = Array(service_ids)
      raw_time = start_time || scheduled_at
      @start_time = raw_time.is_a?(String) ? Time.zone.parse(raw_time) : raw_time
      @customer_params = customer_params
    end

    def call
      return error_result("Start time must be provided") if @start_time.nil?
      return error_result("Services must be provided") if @service_ids.empty?

      services = @business.services.where(id: @service_ids)
      return error_result("One or more services do not belong to this business") if services.count != @service_ids.count

      total_duration = services.sum(:duration_minutes)
      return error_result("Service duration cannot be zero") if total_duration.zero?

      end_time = @start_time + total_duration.minutes

      booking = nil
      ActiveRecord::Base.transaction do
        # Advisory lock per business — serializes concurrent bookings for same business.
        # pg_advisory_xact_lock is blocking: waits until the lock is available (short waits are OK
        # since each transaction is fast). Released automatically at transaction end.
        ActiveRecord::Base.connection.execute(
          "SELECT pg_advisory_xact_lock(#{@business.id.to_i})"
        )

        # Re-check availability inside lock
        overlap_count = @business.bookings
          .where(status: %w[pending confirmed in_progress])
          .where("scheduled_at < ? AND end_time > ?", end_time, @start_time)
          .count

        if overlap_count >= @business.capacity
          raise ActiveRecord::Rollback
        end

        booking = @business.bookings.new(@customer_params)
        booking.scheduled_at = @start_time
        booking.end_time = end_time
        booking.status = :pending
        booking.source = :online
        booking.services = services

        unless booking.valid?
          raise ActiveRecord::Rollback
        end

        booking.save!
      end

      if booking&.persisted?
        { success: true, booking: booking, error: nil }
      else
        error_msg = booking&.errors&.full_messages&.join(", ") || "Time slot no longer available. Please select another time."
        { success: false, booking: nil, error: error_msg }
      end
    rescue ActiveRecord::RecordInvalid => e
      { success: false, booking: nil, error: e.message }
    end

    private

    def error_result(msg)
      { success: false, booking: nil, error: msg }
    end
  end
end
