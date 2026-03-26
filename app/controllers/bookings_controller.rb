class BookingsController < ApplicationController
  allow_unauthenticated_access # Public endpoint

  def new
    @branch = Branch.includes(:business).find_by!(slug: params[:branch_slug])
    verify_branch_active!
    @business = @branch.business
    @services = @branch.services.active.order(:position)
  end

  def react_new
    @branch = Branch.includes(:business).find_by!(slug: params[:branch_slug])
    verify_branch_active!
    @business = @branch.business
    @services = @branch.services.active.includes(:service_category).order(:position)
  end

  def availability
    @branch = Branch.find_by!(slug: params[:branch_slug])
    verify_branch_active!
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
    @branch = Branch.find_by!(slug: params[:branch_slug])
    verify_branch_active!
    @business = @branch.business
    @services = @branch.services.active.order(:position)

    start_time = if params[:start_time].present?
      Time.zone.parse(params[:start_time])
    elsif params[:scheduled_at].present?
      params[:scheduled_at] # Support old parameter name
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
      render :react_new, status: :unprocessable_entity
    end
  end

  def show
    @branch = Branch.includes(:business).find_by!(slug: params[:branch_slug])
    @business = @branch.business
    @booking = @branch.bookings.find(params[:id])
  end

  private

  def verify_branch_active!
    raise ActiveRecord::RecordNotFound unless @branch.active?
  end

  def booking_params
    params.require(:booking).permit(:customer_name, :customer_phone, :customer_email, :notes)
  end
end
