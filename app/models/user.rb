class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
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

  # Profile completion methods
  def profile_complete?
    name.present? && time_zone.present? && avatar.attached?
  end

  def update_profile_completion!
    update!(profile_completed: profile_complete?)
  end

  private

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
