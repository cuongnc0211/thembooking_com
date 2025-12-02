class BookingsController < ApplicationController
  allow_unauthenticated_access # Public endpoint

  def new
    @business = Business.find_by!(slug: params[:business_slug])
    @services = @business.services.active.order(:position)
  end

  def availability
    @business = Business.find_by!(slug: params[:business_slug])
    service_ids = params[:service_ids] || []
    date = params[:date] ? Date.parse(params[:date]) : Date.current

    # For slot-based availability, we need to get the service(s)
    # For simplicity, calculate total duration from all services
    if service_ids.any?
      services = @business.services.where(id: service_ids)
      total_duration = services.sum(:duration_minutes)

      # Create a temporary service object with combined duration
      # Or use the CheckAvailability with service_ids parameter
      available_times = Bookings::CheckAvailability.new(
        business: @business,
        service_ids: service_ids,
        date: date
      ).call
    else
      available_times = []
    end

    # Return as array of time strings (HH:MM format)
    slots = available_times.map { |time| time.strftime("%H:%M") }

    render json: { available_slots: slots, date: date.to_s }
  rescue Date::Error
    render json: { available_slots: [], error: "Invalid date" }, status: :bad_request
  end

  def create
    @business = Business.find_by!(slug: params[:business_slug])
    @services = @business.services.active.order(:position)

    # Parse start_time from params (format: "YYYY-MM-DD HH:MM")
    start_time = if params[:start_time].present?
      Time.zone.parse(params[:start_time])
    elsif params[:scheduled_at].present?
      params[:scheduled_at] # Support old parameter name
    else
      nil
    end

    result = Bookings::CreateBooking.new(
      business: @business,
      service_ids: params[:service_ids],
      start_time: start_time,
      customer_params: booking_params
    ).call

    # Handle both hash and Result struct responses
    success = result.is_a?(Hash) ? result[:success] : result.success?
    booking = result.is_a?(Hash) ? result[:booking] : result.booking
    error = result.is_a?(Hash) ? result[:error] : result.error

    if success
      redirect_to booking_confirmation_path(@business.slug, booking)
    else
      @error = error
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @business = Business.find_by!(slug: params[:business_slug])
    @booking = @business.bookings.find(params[:id])
  end

  private

  def booking_params
    params.require(:booking).permit(:customer_name, :customer_phone, :customer_email, :notes)
  end
end
