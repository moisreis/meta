# frozen_string_literal: true

# Concern responsible for scheduling performance recalculation when the
# underlying investment cash flow or quota pricing changes.
#
module RecalculatesPerformance
  extend ActiveSupport::Concern

  included do
    after_commit :recalculate_performance, on: %i[create update], if: :performance_relevant_change?
    after_commit :recalculate_performance, on: :destroy
  end

  private

  def recalculate_performance
    affected_periods.each do |period|
      PerformanceHistory.where(fund_investment_id: fund_investment_id, period: period).destroy_all
      RecalculatePerformanceJob.perform_later(
        fund_investment_id: fund_investment_id,
        reference_date: period
      )
    end
  end

  def affected_periods
    return [] unless fund_investment_id.present?

    periods = []

    if saved_change_to_cotization_date?
      old_date, new_date = saved_change_to_cotization_date
      periods << old_date.end_of_month if old_date
      periods << new_date.end_of_month if new_date
    elsif cotization_date.present?
      periods << cotization_date.end_of_month
    end

    periods.compact.uniq
  end

  def performance_relevant_change?
    performance_relevant_attribute_names.any? do |attribute_name|
      saved_change_to_attribute?(attribute_name)
    end
  end

  def performance_relevant_attribute_names
    raise NotImplementedError, "#{self.class.name} must implement performance_relevant_attribute_names"
  end
end
