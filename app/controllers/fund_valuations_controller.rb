# === fund_valuations_controller.rb
#
# Description:: This controller manages the display and monitoring of daily fund quota values
#               imported from CVM and other external sources. It provides admin-only access
#               to verify data integrity and track import status.
#
# Usage:: - *What* - This controller displays fund valuation data for administrative
#           oversight and quality control purposes.
#         - *How* - It filters valuations by date range, fund, and source, presenting
#           paginated results with search capabilities using Ransack.
#         - *Why* - Administrators need visibility into imported market data to ensure
#           the background import jobs are functioning correctly and data is complete.
#
# Attributes:: - *@fund_valuations* [Collection] - The filtered list of valuation records.
#              - *@fund_valuation* [Object] - A single specific valuation record.
#              - *@statistics* [Hash] - Computed summary metrics of the current dataset.
#
class FundValuationsController < ApplicationController

  # =============================================================
  #                        CONFIGURATION
  # =============================================================

  # This ensures only authenticated users can access any action in this controller,
  # protecting sensitive financial data from unauthorized access.
  before_action :authenticate_user!

  # This restricts all actions to admin users only, as fund valuations
  # are infrastructure data that regular users should not directly manage.
  before_action :require_admin

  # This loads common data needed across multiple actions,
  # such as the list of all investment funds for filtering dropdowns.
  before_action :load_filters, only: [:index]

  # =============================================================
  #                       PUBLIC METHODS
  # =============================================================

  # == index
  #
  # @author Moisés Reis
  #
  # This displays a paginated, filterable list of all fund valuations in the system.
  # It supports searching by date range, fund CNPJ, source, and sorting options.
  def index
    if params.dig(:q, :fund_cnpj_cont).present?
      digits = params[:q][:fund_cnpj_cont].gsub(/\D/, "")
      if digits.length == 14
        params[:q][:fund_cnpj_cont] = digits.sub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '\1.\2.\3/\4-\5')
      end
    end

    # Initialize Ransack search object.
    @q = FundValuation.ransack(params[:q])

    # Apply date range filters if provided.
    @q.date_gteq = params[:start_date] if params[:start_date].present?
    @q.date_lteq = params[:end_date] if params[:end_date].present?

    # Execute search without distinct to avoid composite key issues.
    @fund_valuations = @q.result
                         .includes(:investment_fund)
                         .order(date: :desc, fund_cnpj: :asc)
                         .page(params[:page])
                         .per(14)

    # Calculate statistics.
    @statistics = calculate_statistics(@fund_valuations)

    # Total items count.
    @total_items = FundValuation.count

    respond_to do |format|
      format.html
      format.json { render json: @fund_valuations }
    end
  end

  # == show
  #
  # @author Moisés Reis
  #
  # This displays detailed information about a specific fund valuation,
  # including calculated daily changes and historical context.
  def show

    # This finds a single valuation record using the composite primary key
    # (date and fund_cnpj) from the URL parameters.
    @fund_valuation = FundValuation.find([params[:date], params[:fund_cnpj]])

    # This loads recent historical valuations for the same fund to provide
    # context and show trends leading up to the selected date.
    @recent_history = FundValuation.for_fund(@fund_valuation.fund_cnpj)
                                   .where('date <= ?', @fund_valuation.date)
                                   .order(date: :desc)
                                   .limit(30)

    respond_to do |format|
      format.html
      format.json { render json: @fund_valuation }
    end
  rescue ActiveRecord::RecordNotFound

    # This handles cases where the requested valuation does not exist,
    # redirecting the user back with a clear error message.
    redirect_to fund_valuations_path, alert: "Fund valuation not found for the specified date and CNPJ."
  end

  # == data_health
  #
  # @author Moisés Reis
  #
  # This provides a dashboard view showing the overall health and completeness
  # of fund valuation data across all funds and recent time periods.
  def data_health

    # This calculates how many funds have valuations for the most recent
    # business day, helping identify gaps in the import process.
    @funds_with_recent_data = FundValuation.recent(1)
                                           .select(:fund_cnpj)
                                           .distinct
                                           .count

    # This counts the total number of registered investment funds
    # to compare against funds with recent data.
    @total_funds = InvestmentFund.count

    # This identifies which funds are missing recent valuations,
    # alerting admins to potential import failures or delisted funds.
    @funds_missing_data = InvestmentFund.where.not(
      cnpj: FundValuation.recent(1).select(:fund_cnpj)
    ).limit(20)

    # This groups valuations by source to show the distribution
    # of data providers and identify any source-specific issues.
    @valuations_by_source = FundValuation.recent(30)
                                         .group(:source)
                                         .count

    # This calculates the count of valuations per day over the past
    # 30 days to detect any days with abnormally low import counts.
    @daily_import_counts = FundValuation.recent(30)
                                        .group(:date)
                                        .count
                                        .sort
                                        .to_h

    respond_to do |format|
      format.html
      format.json do
        render json: {
          funds_with_recent_data: @funds_with_recent_data,
          total_funds: @total_funds,
          coverage_percentage: (@funds_with_recent_data.to_f / @total_funds * 100).round(2),
          funds_missing_data: @funds_missing_data.pluck(:cnpj, :fund_name),
          valuations_by_source: @valuations_by_source,
          daily_import_counts: @daily_import_counts
        }
      end
    end
  end

  # == trigger_import
  #
  # @author Moisés Reis
  #
  # This manually triggers the background job that imports fund valuations
  # from external sources, useful for testing or recovering from failed imports.
  def trigger_import
    FundValuationImportJob.perform_later
    redirect_to fund_valuations_path, notice: "Importação iniciada."
  end

  def import_progress
    data = Rails.cache.read("fund_valuation_import_progress") ||
           { percent: 0, step: "Aguardando…", done: false }
    render json: data
  end

  # =============================================================
  #                       HELPER UTILITIES
  # =============================================================

  private

  # == require_admin
  #
  # @author Moisés Reis
  #
  # This enforces admin-only access to this controller by checking
  # the current user's role and redirecting non-admins.
  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "You must be an administrator to access this page."
    end
  end

  # == load_filters
  #
  # @author Moisés Reis
  #
  # This preloads data needed for filter dropdowns and search forms,
  # such as the list of all investment funds and available data sources.
  def load_filters

    # This retrieves all investment funds ordered by name for use
    # in the fund selection dropdown on the index page.
    @investment_funds = InvestmentFund.order(:fund_name)

    # This collects all unique source values from existing valuations
    # to populate the source filter dropdown.
    @sources = FundValuation.select(:source).distinct.pluck(:source).compact

    # This sets default date range values if not provided,
    # defaulting to the last 30 days for initial page loads.
    @start_date = params[:start_date] || 30.days.ago.to_date
    @end_date = params[:end_date] || Date.current
  end

  # == calculate_statistics
  #
  # @author Moisés Reis
  #
  # This computes summary statistics about the filtered valuation dataset,
  # providing quick insights into data volume and coverage.
  #
  # Parameters:: - valuations [ActiveRecord::Relation] - The filtered collection of valuations.
  def calculate_statistics(valuations)

    # Build a fresh query from the where conditions to avoid composite key issues.
    where_conditions = valuations.where_values_hash
    base_query = FundValuation.where(where_conditions)

    total_count = base_query.count
    unique_funds_count = base_query.distinct.count(:fund_cnpj)

    {
      total_records: total_count,
      unique_funds: unique_funds_count,
      date_range: {
        earliest: base_query.minimum(:date),
        latest: base_query.maximum(:date)
      },
      average_quota_value: base_query.average(:quota_value)&.round(6)
    }
  end
end