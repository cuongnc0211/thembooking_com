class Business::GenerateDailySlotsJob < ApplicationJob
  queue_as :default

  def perform(business_id)
    business = Business.find_by(id: business_id)

    begin
      result = Slots::GenerateForBusiness.new(business: business).call

      Rails.logger.info("Slot generation for business #{business.id} (#{business.name}): #{result[:message]}")
    rescue StandardError => e
      Rails.logger.error("Failed to generate slots for business #{business.id}: #{e.message}")
      # Continue processing other businesses even if one fails
    end
  end
end
