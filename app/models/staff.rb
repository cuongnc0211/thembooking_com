class Staff < ApplicationRecord
  has_secure_password
  has_many :admin_sessions, dependent: :destroy

  enum :role, { super_admin: 0, developer: 1, sale: 2, accountant: 3 }

  validates :email_address, presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :active, -> { where(active: true) }
end
