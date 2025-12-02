module Dashboard
  class BookingsController < BaseController
    def index
      @business = current_user.business
      @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      @bookings = @business.bookings
                           .includes(:services)
                           .for_date(@date)
                           .by_time

      # Apply status filter if present
      if params[:status].present?
        @bookings = @bookings.where(status: params[:status])
      end

      # Apply service filter if present
      if params[:service_id].present?
        @bookings = @bookings.joins(:booking_services)
                            .where(booking_services: { service_id: params[:service_id] })
                            .distinct
      end

      # Apply search if present
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @bookings = @bookings.where(
          "customer_name ILIKE ? OR customer_phone LIKE ?",
          search_term, search_term
        )
      end

      # For capacity indicator
      @current_capacity = @business.current_capacity_usage
      @total_capacity = @business.capacity
      @capacity_percentage = @business.capacity_percentage

      # For service filter dropdown
      @services = @business.services.active.order(:position)
    end

    def show
      @business = current_user.business
      @booking = @business.bookings.find(params[:id])
    end

    def new
      @business = current_user.business
      @booking = @business.bookings.new
      @services = @business.services.active.order(:position)
    end

    def create
      @business = current_user.business
      @booking = @business.bookings.new(booking_params)
      @booking.source = :walk_in
      @booking.status = :in_progress
      @booking.scheduled_at = Time.current if @booking.scheduled_at.blank?

      if @booking.save
        redirect_to dashboard_bookings_path, notice: "Walk-in customer added successfully"
      else
        @services = @business.services.active.order(:position)
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @business = current_user.business
      @booking = @business.bookings.find(params[:id])

      if @booking.update(booking_params)
        redirect_to dashboard_booking_path(@booking), notice: "Booking updated successfully"
      else
        render :show, status: :unprocessable_entity
      end
    end

    # Status transition actions
    def confirm
      @business = current_user.business
      @booking = @business.bookings.find(params[:id])

      if @booking.update(status: :confirmed)
        redirect_to dashboard_bookings_path, notice: "Booking confirmed"
      else
        redirect_to dashboard_bookings_path, alert: "Failed to confirm booking"
      end
    end

    def start
      @business = current_user.business
      @booking = @business.bookings.find(params[:id])

      if @booking.update(status: :in_progress, started_at: Time.current)
        redirect_to dashboard_bookings_path, notice: "Service started"
      else
        redirect_to dashboard_bookings_path, alert: "Failed to start service"
      end
    end

    def complete
      @business = current_user.business
      @booking = @business.bookings.find(params[:id])

      if @booking.update(status: :completed, completed_at: Time.current)
        redirect_to dashboard_bookings_path, notice: "Booking completed"
      else
        redirect_to dashboard_bookings_path, alert: "Failed to complete booking"
      end
    end

    def cancel
      @business = current_user.business
      @booking = @business.bookings.find(params[:id])

      if @booking.update(status: :cancelled)
        redirect_to dashboard_bookings_path, notice: "Booking cancelled"
      else
        redirect_to dashboard_bookings_path, alert: "Failed to cancel booking"
      end
    end

    def no_show
      @business = current_user.business
      @booking = @business.bookings.find(params[:id])

      if @booking.update(status: :no_show)
        redirect_to dashboard_bookings_path, notice: "Marked as no-show"
      else
        redirect_to dashboard_bookings_path, alert: "Failed to mark as no-show"
      end
    end

    private

    def booking_params
      params.require(:booking).permit(
        :customer_name,
        :customer_phone,
        :customer_email,
        :notes,
        :scheduled_at,
        service_ids: []
      )
    end
  end
end
