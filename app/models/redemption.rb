# === redemption.rb
#
# Description:: Represents a withdrawal transaction from an investment fund position.
#
class Redemption < ApplicationRecord

  after_commit :recalculate_performance, on: [:create, :destroy]

delegate :fund_name, to: :investment_fund
delegate :name,      to: :portfolio, prefix: true  # produces portfolio_name

  # FIX: same sync_dates issue as Application — use ||= to avoid overwriting
  # explicit date values that differ from cotization_date.
  before_validation :sync_dates

  belongs_to :fund_investment

  has_many :redemption_allocations, dependent: :destroy
  has_many :applications, through: :redemption_allocations

  validates :fund_investment_id, presence: true
  validates :request_date,       presence: true

  validates :redeemed_liquid_value, numericality: { greater_than: 0 }, allow_nil: true
  validates :redeemed_quotas,       numericality: { greater_than: 0 }, allow_nil: true
  validates :redemption_yield,      numericality: true,                allow_nil: true

  validates :redemption_type, inclusion: {
    in:      %w[partial total emergency scheduled],
    message: "%{value} isn't a valid redemption type"
  }, allow_blank: true

  validate :cotization_after_request
  validate :liquidation_after_cotization
  validate :sufficient_quotas_available

  scope :pending_cotization,  -> { where(cotization_date: nil) }
  scope :pending_liquidation, -> { where.not(cotization_date: nil).where(liquidation_date: nil) }
  scope :completed,           -> { where.not(liquidation_date: nil) }
  scope :by_type,             ->(type) { where(redemption_type: type) }
  scope :in_date_range,       ->(start_date, end_date) { where(request_date: start_date..end_date) }

  # == completed?
  def completed?
    liquidation_date.present?
  end

  # == sync_dates
  #
  # Back-fills request_date and liquidation_date from cotization_date only when
  # those fields are blank, preserving any explicitly set values.
  def sync_dates
    return unless cotization_date.present?

    self.request_date    ||= cotization_date
    self.liquidation_date ||= cotization_date
  end

  # == effective_quota_value
  def effective_quota_value
    return nil unless redeemed_liquid_value && redeemed_quotas && redeemed_quotas > 0
    redeemed_liquid_value / redeemed_quotas
  end

  # == total_allocated_quotas
  def total_allocated_quotas
    redemption_allocations.sum(:quotas_used) || BigDecimal("0")
  end

  # == allocations_balanced?
  def allocations_balanced?
    return false unless redeemed_quotas
    total_allocated_quotas == redeemed_quotas
  end

  # == return_percentage
  def return_percentage
    return nil unless redemption_yield && redeemed_liquid_value && redemption_yield != 0
    (redemption_yield / (redeemed_liquid_value - redemption_yield)) * 100
  end

  private

def investment_fund = fund_investment.investment_fund
def portfolio       = fund_investment.portfolio

  def performance_relevant_attribute_names
    %w[
      cotization_date
      liquidation_date
      redeemed_liquid_value
      redeemed_quotas
    ]
  end

  def cotization_after_request
    return unless request_date && cotization_date
    if cotization_date < request_date
      errors.add(:cotization_date, "cannot be earlier than the request date")
    end
  end

  def liquidation_after_cotization
    return unless cotization_date && liquidation_date
    if liquidation_date < cotization_date
      errors.add(:liquidation_date, "cannot be earlier than the cotization date")
    end
  end

  # Validates against the denormalised total_quotas_held column using a row lock
  # to prevent a race condition where two concurrent redemptions both pass validation
  # before either has written its delta.
  def sufficient_quotas_available
    return unless fund_investment && redeemed_quotas

    # Lock the parent record so concurrent requests serialise here.
    locked_fi = FundInvestment.lock.find_by(id: fund_investment_id)
    return unless locked_fi

    if redeemed_quotas > locked_fi.total_quotas_held
      errors.add(:redeemed_quotas, "cannot exceed available quotas in the fund investment (#{locked_fi.total_quotas_held} available)")
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[
      cotization_date created_at fund_investment_id id liquidation_date
      redeemed_liquid_value redeemed_quotas redemption_type
      redemption_yield request_date updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[applications fund_investment redemption_allocations]
  end
end
