class BookingsController < ApplicationController
  allow_unauthenticated_access # Public endpoint

  def new
    @branch = Branch.find_by!(slug: params[:business_slug])
    @services = @branch.services.active.order(:position)
  end

  def react_new
    @branch = Branch.find_by!(slug: params[:business_slug])
    @services = @branch.services.active.order(:position)
  end

  def availability
    @branch = Branch.find_by!(slug: params[:business_slug])
    service_ids = params[:service_ids] || []
    date = params[:date] ? Date.parse(params[:date]) : Date.current

    available_times = if service_ids.any?
      Bookings::CheckAvailability.new(
        branch: @branch,
        service_ids: service_ids,
        date: date
      ).call
    else
      []
    end

    slots = available_times.map { |time| time.strftime("%H:%M") }
    render json: { available_slots: slots, date: date.to_s }
  rescue Date::Error
    render json: { available_slots: [], error: "Invalid date" }, status: :bad_request
  end

  def create
    @branch = Branch.find_by!(slug: params[:business_slug])
    @services = @branch.services.active.order(:position)

    # Parse start_time from params (format: "YYYY-MM-DD HH:MM")
    start_time = if params[:start_time].present?
      Time.zone.parse(params[:start_time])
    elsif params[:scheduled_at].present?
      params[:scheduled_at] # Support old parameter name
    else
      nil
    end

    result = Bookings::CreateBooking.new(
      branch: @branch,
      service_ids: params[:service_ids],
      start_time: start_time,
      customer_params: booking_params
    ).call

    if result[:success]
      redirect_to booking_confirmation_path(@branch.slug, result[:booking])
    else
      @error = result[:error]
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @branch = Branch.find_by!(slug: params[:business_slug])
    @booking = @branch.bookings.find(params[:id])
  end

  private

  def booking_params
    params.require(:booking).permit(:customer_name, :customer_phone, :customer_email, :notes)
  end
end
