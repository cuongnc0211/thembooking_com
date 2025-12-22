class TestJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Do something later
    Rails.logger.info "Solid Queue is working! Args: #{args.inspect}"
    (1..100).to_a.each do |n|
      Rails.logger.info "Solid Queue is working! Test Job: #{n}"
      sleep 1
    end
  end
end
