class PromotionCode < ApplicationRecord
  enum :discount_type, { percentage: 0, fixed_amount: 1 }

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :discount_type, presence: true
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :discount_value, numericality: { less_than_or_equal_to: 100 }, if: :percentage?
  validates :usage_limit, numericality: { greater_than: 0 }, allow_nil: true
  validates :valid_until, comparison: { greater_than: :valid_from }, allow_blank: true, if: -> { valid_from.present? && valid_until.present? }

  before_validation :upcase_code

  scope :currently_valid, -> {
    where(active: true)
      .where("valid_from IS NULL OR valid_from <= ?", Time.current)
      .where("valid_until IS NULL OR valid_until >= ?", Time.current)
  }

  # Finds an active, non-expired, under-limit code and increments used_count.
  # Raises ActiveRecord::RecordNotFound or ActiveRecord::RecordInvalid if invalid.
  # Uses with_lock to prevent race conditions on concurrent redemptions.
  def self.redeem!(code)
    record = currently_valid.find_by!(code: code.to_s.upcase)
    record.with_lock do
      # Re-check inside lock to prevent TOCTOU race conditions
      raise ActiveRecord::RecordInvalid.new(record), "Inactive or expired" unless record.currently_valid?
      raise ActiveRecord::RecordInvalid.new(record), "Usage limit reached" if record.usage_limit && record.used_count >= record.usage_limit
      record.increment!(:used_count)
    end
    record
  end

  def currently_valid?
    active? &&
      (valid_from.nil? || valid_from <= Time.current) &&
      (valid_until.nil? || valid_until >= Time.current)
  end

  def expired?
    valid_until.present? && valid_until < Time.current
  end

  def usage_remaining
    usage_limit ? (usage_limit - used_count) : nil
  end

  private

  def upcase_code
    self.code = code&.upcase&.strip
  end
end
