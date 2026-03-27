class BookingsController < ApplicationController
  allow_unauthenticated_access # Public endpoint
  layout "booking"

  def react_new
    @business = Business.find_by!(slug: params[:business_slug])
    @branches = @business.branches
                         .where(active: true)
                         .includes(services: :service_category)
                         .order(:position)
  end

  def availability
    @business = Business.find_by!(slug: params[:business_slug])
    @branch = @business.branches.find_by!(slug: params[:branch_slug])
    raise ActiveRecord::RecordNotFound unless @branch.active?

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
    @business = Business.find_by!(slug: params[:business_slug])
    @branch = @business.branches.find_by!(slug: params[:branch_slug])
    raise ActiveRecord::RecordNotFound unless @branch.active?

    start_time = if params[:start_time].present?
      Time.zone.parse(params[:start_time])
    elsif params[:scheduled_at].present?
      params[:scheduled_at]
    end

    result = Bookings::CreateBooking.new(
      branch: @branch,
      service_ids: params[:service_ids],
      start_time: start_time,
      customer_params: booking_params
    ).call

    if result[:success]
      redirect_to booking_confirmation_path(@business.slug, result[:booking])
    else
      @branches = @business.branches.where(active: true).includes(services: :service_category).order(:position)
      @error = result[:error]
      render :react_new, status: :unprocessable_entity
    end
  end

  def show
    @business = Business.find_by!(slug: params[:business_slug])
    @booking = Booking.joins(:branch)
                      .where(branches: { business_id: @business.id })
                      .find(params[:id])
    @branch = @booking.branch
  end

  private

  def booking_params
    params.require(:booking).permit(:customer_name, :customer_phone, :customer_email, :notes)
  end
end
