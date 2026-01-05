# === dashboard_controller
#
# @author Moisés Reis
# @added 11/24/2025
# @package *Meta*
# @description This controller manages the main personalized overview page (dashboard)
#              for the currently authenticated user. It serves as the primary landing
#              page after login and displays summary data from modules like **FundInvestment**
#              and **Application**.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the initial page a user sees, which
#           summarizes their activity and key metrics.
#         - *[How]* It aggregates data from portfolios, fund investments, applications,
#           and redemptions to calculate financial metrics and prepare visualization data.
#         - *[Why]* It provides the user with immediate context and quick access to
#           the most important application features.
#
class DashboardController < ApplicationController

  # Explanation:: This runs before any action and ensures the current user is
  #               successfully logged into the system before they can access the dashboard.
  before_action :authenticate_user!

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action serves as the main entry point for the dashboard.
  #        It calculates aggregated financial metrics, prepares chart data,
  #        and loads recent activity before rendering the dashboard view.
  #
  def index
    calculate_portfolio_metrics
    prepare_chart_data
    load_recent_activity
  end

  private

  # == calculate_portfolio_metrics
  #
  # @author Moisés Reis
  # @category *Calculation*
  #
  # Calculation:: This method aggregates financial data across all user portfolios
  #               to calculate total invested value, current market value, quotas held,
  #               and performance metrics like gain/loss and ROI.
  #
  def calculate_portfolio_metrics

    # Explanation:: This calculates the sum of all money invested across all portfolios
    #               by iterating through fund investments and summing their total invested values.
    @total_invested = current_user.portfolios.sum do |portfolio|
      portfolio.fund_investments.sum(:total_invested_value) || 0
    end

    # Explanation:: This calculates the total number of quotas held across all investments
    #               by summing the total_quotas_held field from each fund investment.
    @total_quotas = current_user.portfolios.sum do |portfolio|
      portfolio.fund_investments.sum(:total_quotas_held) || 0
    end

    # Explanation:: This calculates the current market value by summing the market value
    #               of each fund investment, which multiplies quotas held by latest quota price.
    @total_market_value = current_user.portfolios.sum do |portfolio|
      portfolio.fund_investments.sum(&:current_market_value)
    end

    # Explanation:: This calculates the absolute gain or loss by subtracting the original
    #               invested amount from the current market value.
    @total_gain_loss = @total_market_value - @total_invested

    # Explanation:: This determines if the overall position is in profit by checking
    #               if the gain/loss value is positive.
    @gain_is_positive = @total_gain_loss > 0

    # Explanation:: This determines if the overall position is in loss by checking
    #               if the gain/loss value is negative.
    @gain_is_negative = @total_gain_loss < 0

    # Explanation:: This determines styling for market value display by comparing
    #               current market value against the original investment.
    @market_is_positive = @total_market_value > @total_invested
    @market_is_negative = @total_market_value < @total_invested

    # Explanation:: This calculates the return on investment as a percentage by dividing
    #               gain/loss by the original investment and multiplying by 100.
    @roi = @total_invested > 0 ? ((@total_market_value - @total_invested) / @total_invested * 100) : 0

    # Explanation:: This determines if the ROI percentage is positive for styling purposes.
    @roi_positive = @roi > 0

    # Explanation:: This determines if the ROI percentage is negative for styling purposes.
    @roi_negative = @roi < 0

    # Explanation:: This counts the total number of unique investment funds across all
    #               portfolios by collecting fund IDs and removing duplicates.
    @unique_funds = current_user.portfolios.flat_map do |portfolio|
      portfolio.fund_investments.map(&:investment_fund_id)
    end.uniq.count

    # Explanation:: This calculates the total number of transactions by summing applications
    #               and redemptions across all portfolios owned by the current user.
    @total_transactions = Application.joins(fund_investment: :portfolio)
                                     .where(portfolios: { user_id: current_user.id })
                                     .count +
                          Redemption.joins(fund_investment: :portfolio)
                                    .where(portfolios: { user_id: current_user.id })
                                    .count
  end

  # == prepare_chart_data
  #
  # @author Moisés Reis
  # @category *Data Preparation*
  #
  # Data Preparation:: This method prepares structured data for rendering charts
  #                    in the dashboard view, including portfolio allocation distribution
  #                    and monthly transaction flow analysis.
  #
  def prepare_chart_data

    # Explanation:: This builds a hash mapping portfolio names to their total invested values
    #               for the portfolio allocation pie chart, excluding portfolios with zero value.
    @portfolio_allocation = {}
    current_user.portfolios.each do |portfolio|
      portfolio_value = portfolio.fund_investments.sum(:total_invested_value) || 0
      @portfolio_allocation[portfolio.name] = portfolio_value if portfolio_value > 0
    end

    # Explanation:: This initializes an empty hash to store monthly transaction flow data
    #               which will track both applications and redemptions by month.
    @monthly_flows = {}

    # Explanation:: This retrieves all application transactions for the user and groups them
    #               by month, summing the financial values for each month's applications.
    applications = Application.joins(fund_investment: :portfolio)
                              .where(portfolios: { user_id: current_user.id })
                              .where.not(request_date: nil)

    applications.each do |app|
      month_key = app.request_date.strftime("%m/%Y")
      @monthly_flows[month_key] ||= { "Aplicações" => 0, "Resgates" => 0 }
      @monthly_flows[month_key]["Aplicações"] += app.financial_value || 0
    end

    # Explanation:: This retrieves all redemption transactions for the user and groups them
    #               by month, summing the redeemed liquid values for each month's redemptions.
    redemptions = Redemption.joins(fund_investment: :portfolio)
                            .where(portfolios: { user_id: current_user.id })
                            .where.not(request_date: nil)

    redemptions.each do |red|
      month_key = red.request_date.strftime("%m/%Y")
      @monthly_flows[month_key] ||= { "Aplicações" => 0, "Resgates" => 0 }
      @monthly_flows[month_key]["Resgates"] += red.redeemed_liquid_value || 0
    end

    # Explanation:: This sorts the monthly flow data chronologically by parsing the month/year
    #               keys and converting back to a hash for proper chart rendering.
    @monthly_flows = @monthly_flows.sort_by { |k, v| Date.strptime(k, "%m/%Y") }.to_h
  end

  # == load_recent_activity
  #
  # @author Moisés Reis
  # @category *Data Loading*
  #
  # Data Loading:: This method loads the most recent transactions (applications and redemptions)
  #                for display in the dashboard's activity feed sections.
  #
  def load_recent_activity

    # Explanation:: This retrieves the 5 most recent application transactions made by the user
    #               across all their portfolios, including related fund and portfolio data.
    @recent_applications = Application.joins(fund_investment: :portfolio)
                                      .where(portfolios: { user_id: current_user.id })
                                      .includes(fund_investment: [:portfolio, :investment_fund])
                                      .order(request_date: :desc)
                                      .limit(5)

    # Explanation:: This retrieves the 5 most recent redemption transactions made by the user
    #               across all their portfolios, including related fund and portfolio data.
    @recent_redemptions = Redemption.joins(fund_investment: :portfolio)
                                    .where(portfolios: { user_id: current_user.id })
                                    .includes(fund_investment: [:portfolio, :investment_fund])
                                    .order(request_date: :desc)
                                    .limit(5)
  end
end