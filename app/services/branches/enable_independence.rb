module Branches
  # Breaks inheritance from the main branch by copying its services and
  # operating hours to this branch, then setting inherit_from_main to false.
  class EnableIndependence
    def initialize(branch)
      @branch = branch
      @main = branch.business.branches.find_by!(is_main: true)
    end

    def call
      return false if @branch.is_main?

      ActiveRecord::Base.transaction do
        copy_services
        @branch.update!(
          operating_hours: @main.operating_hours.deep_dup,
          inherit_from_main: false
        )
      end
      true
    rescue => e
      Rails.logger.error "Branches::EnableIndependence failed for branch #{@branch.id}: #{e.message}"
      false
    end

    private

    def copy_services
      @main.services.each do |service|
        @branch.services.create!(
          service.attributes.except("id", "branch_id", "created_at", "updated_at")
        )
      end
    end
  end
end
