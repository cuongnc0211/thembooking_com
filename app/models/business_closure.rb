class BusinessClosure < ApplicationRecord
  belongs_to :business

  validates :date, presence: true
  validates :date, uniqueness: { scope: :business_id, message: "already has a closure on this date" }
  validates :reason, length: { maximum: 255 }, allow_blank: true
  validate :date_not_in_past, on: :create

  scope :upcoming, -> { where("date >= ?", Date.current).order(:date) }
  scope :for_date, ->(date) { where(date: date) }

  private

  def date_not_in_past
    return if date.blank?
    errors.add(:date, "cannot be in the past") if date < Date.current
  end
end
