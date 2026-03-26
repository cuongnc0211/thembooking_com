class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :admin_session

  delegate :user, to: :session, allow_nil: true
  delegate :staff, to: :admin_session, allow_nil: true
end
