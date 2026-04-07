# frozen_string_literal: true

# == ApplicationsHelper
#
# @author Moisés Reis
# @project Meta Investimentos
# @added 06/04/2026
# @package Meta
# @category Helpers
#
# @description
#   Provides calculation and validation logic for Application records. This helper
#   manages quota allocations, processing time metrics, and financial consistency
#   checks for investment applications.
#
# @example Basic usage in views
#   application_metrics(@application)
#   # => { allocated_quotas: 150.0, allocation_percentage: 15.0, ... }
#
module ApplicationsHelper
  # == application_allocated_quotas
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the total quotas allocated from a specific application to redemptions.
  #
  # @param application [Application] The application record
  # @return [Numeric] Total quotas used in redemption allocations
  #
  # @example
  #   application_allocated_quotas(app)
  #   # => 500.25
  #
  def application_allocated_quotas(application)
    application.redemption_allocations.sum(:quotas_used) || 0
  end

  # == application_allocation_percentage
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the percentage of quotas that have been allocated to redemptions.
  #
  # @param application [Application] The application record
  # @return [Numeric] Percentage of allocated quotas (0-100)
  #
  # @example
  #   application_allocation_percentage(app)
  #   # => 75.5
  #
  def application_allocation_percentage(application)
    allocated = application_allocated_quotas(application)
    total = application.number_of_quotas

    return 0 unless total && total > 0

    (allocated / total * 100).round(2)
  end

  # == application_processing_days
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Calculates the number of days elapsed between the request and liquidation dates.
  #
  # @param application [Application] The application record
  # @return [Integer, nil] Number of processing days or nil if dates are missing
  #
  def application_processing_days(application)
    return nil unless application.request_date && application.liquidation_date

    (application.liquidation_date - application.request_date).to_i
  end

  # == application_quota_consistent?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Checks if the calculated quota value matches the stored value within a specific tolerance.
  #
  # @param application [Application] The application record
  # @param tolerance [Numeric] Acceptable difference threshold (default: 0.01)
  # @return [Boolean] True if values are consistent within tolerance
  #
  def application_quota_consistent?(application, tolerance: 0.01)
    calculated = application.calculated_quota_value
    stored = application.quota_value_at_application

    return false unless calculated && stored

    (calculated - stored).abs <= tolerance
  end

  # == application_cotization_valid?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Validates that the cotization date is chronologically after or equal to the request date.
  #
  # @param application [Application] The application record
  # @return [Boolean] True if dates are in valid chronological order
  #
  def application_cotization_valid?(application)
    return true unless application.cotization_date && application.request_date

    application.cotization_date >= application.request_date
  end

  # == application_liquidation_valid?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Validates that the liquidation date is chronologically after or equal to the cotization date.
  #
  # @param application [Application] The application record
  # @return [Boolean] True if dates are in valid chronological order
  #
  def application_liquidation_valid?(application)
    return true unless application.liquidation_date && application.cotization_date

    application.liquidation_date >= application.cotization_date
  end

  # == application_positive_values?
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Validation
  #
  # @description
  #   Checks if the financial value and number of quotas are greater than zero.
  #
  # @param application [Application] The application record
  # @return [Boolean] True if all values are greater than zero
  #
  def application_positive_values?(application)
    financial_valid = application.financial_value && application.financial_value > 0
    quotas_valid = !application.number_of_quotas || application.number_of_quotas > 0

    financial_valid && quotas_valid
  end

  # == application_validations
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Returns a hash containing all validation states for the specific application.
  #
  # @param application [Application] The application record
  # @return [Hash] Validation results with descriptive keys
  #
  # @see #application_cotization_valid?
  # @see #application_liquidation_valid?
  # @see #application_quota_consistent?
  # @see #application_positive_values?
  #
  def application_validations(application)
    {
      cotization_valid: application_cotization_valid?(application),
      liquidation_valid: application_liquidation_valid?(application),
      quota_consistent: application_quota_consistent?(application),
      positive_values: application_positive_values?(application)
    }
  end

  # == application_metrics
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Returns a hash with all calculated metrics for the application, including quotas and days.
  #
  # @param application [Application] The application record
  # @return [Hash] Calculated metrics with descriptive keys
  #
  # @see #application_allocated_quotas
  # @see #application_allocation_percentage
  # @see #application_processing_days
  #
  def application_metrics(application)
    {
      allocated_quotas: application_allocated_quotas(application),
      allocation_percentage: application_allocation_percentage(application),
      processing_days: application_processing_days(application)
    }
  end

  # == application_status_text
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Returns localized formatted text and status flags for the application's current state.
  #
  # @param application [Application] The application record
  # @return [Hash] Status information including completed boolean and display text
  #
  def application_status_text(application)
    {
      completed: application.completed?,
      status_text: application.completed? ? "Finalizada" : "Em processamento",
      detail_text: application.completed? ? "Completa" : "Pendente"
    }
  end

  # == application_quota_availability
  #
  # @author Moisés Reis
  # @project Meta Investimentos
  # @category Read
  #
  # @description
  #   Summarizes quota availability, calculating remaining balance based on allocations.
  #
  # @param application [Application] The application record
  # @return [Hash] Quota availability information (total, allocated, available, percentage)
  #
  def application_quota_availability(application)
    metrics = application_metrics(application)
    total = application.number_of_quotas || 0
    allocated = metrics[:allocated_quotas]
    available = [total - allocated, 0].max

    {
      total: total,
      allocated: allocated,
      available: available,
      percentage: metrics[:allocation_percentage]
    }
  end
end
