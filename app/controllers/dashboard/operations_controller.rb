module Dashboard
  class OperationsController < BaseController
    before_action :set_branch

    def show
      # Renders HTML shell — React mounts via #react-operations-root
    end

    def data
      today = Date.current
      today_bookings = @branch.bookings
                              .includes(booking_services: :service)
                              .for_date(today)
                              .where.not(status: [ :cancelled, :no_show ])
                              .by_time

      in_service = today_bookings.select(&:in_progress?)
      waiting    = today_bookings.select { |b| b.confirmed? && b.scheduled_at >= Time.current }

      render json: {
        branch: { name: @branch.name, capacity: @branch.capacity },
        in_service: serialize_bookings(in_service),
        waiting: serialize_bookings(waiting),
        today_schedule: serialize_bookings(today_bookings),
        counts: {
          in_service: in_service.size,
          waiting: waiting.size,
          completed_today: @branch.bookings.where(scheduled_at: today.all_day, status: :completed).count,
          total_today: today_bookings.size
        }
      }
    end

    def services_list
      services = @branch.services.active.order(:position)
      render json: services.map { |s|
        { id: s.id, name: s.name, duration_minutes: s.duration_minutes, price_cents: s.price_cents }
      }
    end

    private

    def set_branch
      business = current_user.business
      return redirect_to(dashboard_onboarding_path, alert: "Please complete business setup first.") unless business

      @branch = business.branches.find(params[:branch_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to dashboard_branches_path, alert: "Branch not found."
    end

    def serialize_bookings(bookings)
      bookings.map do |b|
        {
          id: b.id,
          customer_name: b.customer_name,
          customer_phone: b.customer_phone,
          scheduled_at: b.scheduled_at.iso8601,
          started_at: b.started_at&.iso8601,
          end_time: b.end_time&.iso8601,
          status: b.status,
          source: b.source,
          notes: b.notes,
          elapsed_minutes: b.started_at ? ((Time.current - b.started_at) / 60).round : nil,
          total_duration_minutes: b.total_duration_minutes,
          services: b.services.map { |s| { id: s.id, name: s.name, duration_minutes: s.duration_minutes } },
          seat_number: nil,
          staff_id: nil
        }
      end
    end
  end
end
