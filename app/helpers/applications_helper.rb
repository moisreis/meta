# frozen_string_literal: true

module ApplicationsHelper
  # Calculates the total quotas allocated from this application to redemptions
  #
  # @param application [Application] the application record
  # @return [Numeric] total quotas used in redemption allocations
  def application_allocated_quotas(application)
    application.redemption_allocations.sum(:quotas_used) || 0
  end

  # Calculates the percentage of quotas that have been allocated to redemptions
  #
  # @param application [Application] the application record
  # @return [Numeric] percentage of allocated quotas (0-100)
  def application_allocation_percentage(application)
    allocated = application_allocated_quotas(application)
    total = application.number_of_quotas

    return 0 unless total && total > 0

    (allocated / total * 100).round(2)
  end

  # Calculates the number of days between request and liquidation
  #
  # @param application [Application] the application record
  # @return [Integer, nil] number of processing days or nil if dates are missing
  def application_processing_days(application)
    return nil unless application.request_date && application.liquidation_date

    (application.liquidation_date - application.request_date).to_i
  end

  # Checks if the calculated quota value matches the stored value
  #
  # @param application [Application] the application record
  # @param tolerance [Numeric] acceptable difference threshold (default: 0.01)
  # @return [Boolean] true if values are consistent within tolerance
  def application_quota_consistent?(application, tolerance: 0.01)
    calculated = application.calculated_quota_value
    stored = application.quota_value_at_application

    return false unless calculated && stored

    (calculated - stored).abs <= tolerance
  end

  # Validates that cotization date is after or equal to request date
  #
  # @param application [Application] the application record
  # @return [Boolean] true if dates are in valid chronological order
  def application_cotization_valid?(application)
    return true unless application.cotization_date && application.request_date

    application.cotization_date >= application.request_date
  end

  # Validates that liquidation date is after or equal to cotization date
  #
  # @param application [Application] the application record
  # @return [Boolean] true if dates are in valid chronological order
  def application_liquidation_valid?(application)
    return true unless application.liquidation_date && application.cotization_date

    application.liquidation_date >= application.cotization_date
  end

  # Checks if all financial values are positive
  #
  # @param application [Application] the application record
  # @return [Boolean] true if all values are greater than zero
  def application_positive_values?(application)
    financial_valid = application.financial_value && application.financial_value > 0
    quotas_valid = !application.number_of_quotas || application.number_of_quotas > 0

    financial_valid && quotas_valid
  end

  # Returns a hash with all validation states for the application
  #
  # @param application [Application] the application record
  # @return [Hash] validation results with descriptive keys
  def application_validations(application)
    {
      cotization_valid: application_cotization_valid?(application),
      liquidation_valid: application_liquidation_valid?(application),
      quota_consistent: application_quota_consistent?(application),
      positive_values: application_positive_values?(application)
    }
  end

  # Returns a hash with all calculated metrics for the application
  #
  # @param application [Application] the application record
  # @return [Hash] calculated metrics with descriptive keys
  def application_metrics(application)
    {
      allocated_quotas: application_allocated_quotas(application),
      allocation_percentage: application_allocation_percentage(application),
      processing_days: application_processing_days(application)
    }
  end

  # Returns formatted text for application status
  #
  # @param application [Application] the application record
  # @return [Hash] status information with text and boolean state
  def application_status_text(application)
    {
      completed: application.completed?,
      status_text: application.completed? ? "Finalizada" : "Em processamento",
      detail_text: application.completed? ? "Completa" : "Pendente"
    }
  end

  # Returns quota availability summary
  #
  # @param application [Application] the application record
  # @return [Hash] quota availability information
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
