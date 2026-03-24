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

      # Determine source and status — JSON requests (React) may supply them; HTML form defaults to walk_in/in_progress
      if request.format.json?
        @booking.source = params.dig(:booking, :source).presence || :walk_in
        @booking.status = params.dig(:booking, :status).presence || :in_progress
      else
        @booking.source = :walk_in
        @booking.status = :in_progress
      end

      @booking.scheduled_at = Time.current if @booking.scheduled_at.blank?
      @booking.started_at   = Time.current if @booking.in_progress?

      # Auto-compute end_time from selected services when not provided
      if @booking.end_time.blank? && @booking.service_ids.present?
        total_duration = Service.where(id: @booking.service_ids).sum(:duration_minutes)
        @booking.end_time = @booking.scheduled_at + total_duration.minutes
      end

      respond_to do |format|
        if @booking.save
          format.html { redirect_to dashboard_branch_bookings_path(@branch), notice: "Walk-in customer added successfully" }
          format.json { render json: { id: @booking.id, status: @booking.status }, status: :created }
        else
          format.html do
            @services = @branch.services.active.order(:position)
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity }
        end
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
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), notice: "Booking confirmed" }
          format.json { render json: { id: @booking.id, status: @booking.status }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to confirm booking" }
          format.json { render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def start
      if @booking.update(status: :in_progress, started_at: Time.current)
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), notice: "Service started" }
          format.json { render json: { id: @booking.id, status: @booking.status }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to start service" }
          format.json { render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def complete
      if @booking.update(status: :completed, completed_at: Time.current)
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), notice: "Booking completed" }
          format.json { render json: { id: @booking.id, status: @booking.status }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to complete booking" }
          format.json { render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def cancel
      if @booking.update(status: :cancelled)
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), notice: "Booking cancelled" }
          format.json { render json: { id: @booking.id, status: @booking.status }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to cancel booking" }
          format.json { render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def no_show
      if @booking.update(status: :no_show)
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), notice: "Marked as no-show" }
          format.json { render json: { id: @booking.id, status: @booking.status }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to dashboard_branch_bookings_path(@branch), alert: "Failed to mark as no-show" }
          format.json { render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity }
        end
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
        :source,
        :status,
        service_ids: []
      )
    end
  end
end
