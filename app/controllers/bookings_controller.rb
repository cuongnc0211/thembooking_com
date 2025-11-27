class BookingsController < ApplicationController
  allow_unauthenticated_access # Public endpoint

  def new
    @business = Business.find_by!(slug: params[:business_slug])
    @services = @business.services.active.order(:position)
  end

  def availability
    @business = Business.find_by!(slug: params[:business_slug])
    service_ids = params[:service_ids] || []
    date = Date.parse(params[:date])

    slots = Bookings::CheckAvailability.new(
      business: @business,
      service_ids: service_ids,
      date: date
    ).call

    render json: { available_slots: slots }
  rescue Date::Error
    render json: { available_slots: [] }, status: :bad_request
  end

  def create
    @business = Business.find_by!(slug: params[:business_slug])
    @services = @business.services.active.order(:position)

    result = Bookings::CreateBooking.new(
      business: @business,
      service_ids: params[:service_ids],
      scheduled_at: params[:scheduled_at],
      customer_params: booking_params
    ).call

    if result.success?
      redirect_to booking_confirmation_path(@business.slug, result.booking)
    else
      @error = result.error
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
