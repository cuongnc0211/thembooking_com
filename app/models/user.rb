class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :business, dependent: :destroy
  has_one_attached :avatar

  # Validations
  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :phone, format: { with: /\A[0-9\s\-\+\(\)]+\z/, message: "only allows numbers and basic formatting" }, allow_blank: true
  validates :time_zone, inclusion: { in: ActiveSupport::TimeZone.all.map(&:name) }, allow_blank: true
  validate :avatar_format

  # Normalize email before save
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Callbacks
  before_validation :normalize_timezone
  before_create :generate_confirmation_token
  after_create :send_confirmation_email

  # Email confirmation methods
  def confirmed?
    email_confirmed_at.present?
  end

  def confirm!
    update!(email_confirmed_at: Time.current, email_confirmation_token: nil)
  end

  def send_confirmation_instructions
    generate_confirmation_token unless email_confirmation_token.present?
    update!(email_confirmation_sent_at: Time.current)
    UserMailer.confirmation_instructions(self).deliver_later
  end

  def confirmation_token_expired?
    return false if email_confirmation_sent_at.nil?
    email_confirmation_sent_at < 24.hours.ago
  end

  private

  def normalize_timezone
    return if time_zone.blank?

    # Check if it's already a valid ActiveSupport timezone name
    if ActiveSupport::TimeZone.all.map(&:name).include?(time_zone)
      # Already valid, do nothing
      return
    end

    # Try to find a matching ActiveSupport timezone by IANA identifier
    # This handles browser-detected timezones like "Asia/Ho_Chi_Minh"
    matched_zone = ActiveSupport::TimeZone.all.find do |zone|
      zone.tzinfo.name == time_zone || zone.tzinfo.identifier == time_zone
    end

    if matched_zone
      self.time_zone = matched_zone.name
      return
    end

    # If not found by identifier, try matching by UTC offset
    # This handles cases like "Asia/Ho_Chi_Minh" which should map to "Bangkok" or "Hanoi"
    begin
      tz_info = TZInfo::Timezone.get(time_zone)
      target_offset = tz_info.current_period.offset.utc_total_offset

      matched_zone = ActiveSupport::TimeZone.all.find do |zone|
        zone.tzinfo.current_period.offset.utc_total_offset == target_offset
      end

      if matched_zone
        self.time_zone = matched_zone.name
      else
        # If no match found, set to nil instead of keeping invalid value
        self.time_zone = nil
      end
    rescue TZInfo::InvalidTimezoneIdentifier
      # Invalid timezone identifier, set to nil to avoid validation error
      self.time_zone = nil
    end
  end

  def generate_confirmation_token
    self.email_confirmation_token = SecureRandom.urlsafe_base64(32)
  end

  def send_confirmation_email
    send_confirmation_instructions
  end

  def avatar_format
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:avatar, 'must be a JPEG, PNG, or GIF')
    end

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, 'size must be less than 5MB')
    end
  end
end
