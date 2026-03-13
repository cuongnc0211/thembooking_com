module Dashboard
  class BookingsController < BaseController
    before_action :set_branch
    before_action :set_booking, only: [ :show, :edit, :update, :confirm, :start, :complete, :cancel, :no_show ]

    def index
      @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      @bookings = @branch.bookings
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

      # Capacity indicator from branch
      @current_capacity = @branch.current_capacity_usage
      @total_capacity = @branch.capacity
      @capacity_percentage = @branch.capacity_percentage

      # For service filter dropdown
      @services = @branch.services.active.order(:position)
    end

    def show; end

    def new
      @booking = @branch.bookings.new
      @services = @branch.services.active.order(:position)
    end

    def create
      @booking = @branch.bookings.new(booking_params)
      @booking.source = :walk_in
      @booking.status = :in_progress
      @booking.scheduled_at = Time.current if @booking.scheduled_at.blank?

      if @booking.save
        redirect_to dashboard_branch_bookings_path(@branch), notice: "Walk-in customer added successfully"
      else
        @services = @branch.services.active.order(:position)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @services = @branch.services.active.order(:position)
    end

    def update
      if @booking.update(booking_params)
        redirect_to dashboard_branch_booking_path(@branch, @booking), notice: "Booking updated successfully"
      else
        @services = @branch.services.active.order(:position)
        render :edit, status: :unprocessable_entity
      end
    end

    # Status transition actions
    def confirm
      if @booking.update(status: :confirmed)
        redirect_to dashboard_branch_bookings_path(@branch), notice: "Booking confirmed"
      else
        redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to confirm booking"
      end
    end

    def start
      if @booking.update(status: :in_progress, started_at: Time.current)
        redirect_to dashboard_branch_bookings_path(@branch), notice: "Service started"
      else
        redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to start service"
      end
    end

    def complete
      if @booking.update(status: :completed, completed_at: Time.current)
        redirect_to dashboard_branch_bookings_path(@branch), notice: "Booking completed"
      else
        redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to complete booking"
      end
    end

    def cancel
      if @booking.update(status: :cancelled)
        redirect_to dashboard_branch_bookings_path(@branch), notice: "Booking cancelled"
      else
        redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to cancel booking"
      end
    end

    def no_show
      if @booking.update(status: :no_show)
        redirect_to dashboard_branch_bookings_path(@branch), notice: "Marked as no-show"
      else
        redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to mark as no-show"
      end
    end

    private

    def set_branch
      business = current_user.business
      return redirect_to(dashboard_onboarding_path, alert: "Please complete business setup first.") unless business

      @branch = business.branches.find(params[:branch_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_branches_path, alert: "Branch not found."
    end

    def set_booking
      @booking = @branch.bookings.find(params[:id])
    end

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
