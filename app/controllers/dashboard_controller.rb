# === dashboard_controller.rb
#
# Description:: This controller serves as the intelligence hub of the app,
#               gathering data from **Portfolios**, **Applications**, and
#               **Redemptions** to build a visual summary of the user's
#               entire financial situation.
#
# Usage:: - *What* - A high-level overview page that shows totals, gains,
#           losses, and performance charts at a single glance.
#         - *How* - It calculates math across all investments and prepares
#           organized data structures for interactive charts.
#         - *Why* - It helps users quickly understand how their money is
#           growing and where their biggest investments are located.
#
# Attributes:: - *@total_market_value* [Decimal] - The current worth of all assets.
#              - *@roi* [Percentage] - The return on investment ratio.
#              - *@monthly_flows* [Hash] - Data used for cash-flow bar charts.
#
class DashboardController < ApplicationController

  # This security check ensures that only users who have logged
  # into the system can access their private financial dashboard.
  before_action :authenticate_user!

  # == index
  #
  # @author Moisés Reis
  #
  # This is the main action that triggers all the math and data
  # gathering needed to populate the dashboard view. It calls
  # specialized helpers to handle metrics, charts, and activity.
  def index

    # Triggers the calculation of all global financial totals.
    calculate_portfolio_metrics

    # Formats the data into structures that the charts can read.
    prepare_chart_data

    # Fetches the most recent transactions to show in the history feed.
    load_recent_activity
  end

  private

  # == calculate_portfolio_metrics
  #
  # @author Moisés Reis
  #
  # This helper sums up the values of every investment the user owns.
  # It works out the total invested amount, the current market worth,
  # and whether the user is currently seeing a profit or a loss.
  def calculate_portfolio_metrics

    # Adds up the original cost of every investment across all portfolios.
    @total_invested = current_user.portfolios.sum do |portfolio|
      portfolio.fund_investments.sum(:total_invested_value) || 0
    end

    # Sums up the total number of shares/quotas the user currently holds.
    @total_quotas = current_user.portfolios.sum do |portfolio|
      portfolio.fund_investments.sum(:total_quotas_held) || 0
    end

    # Calculates the current value by checking the latest available share prices.
    @total_market_value = current_user.portfolios.sum do |portfolio|
      portfolio.fund_investments.sum(&:current_market_value)
    end

    # Determines the absolute money gained or lost compared to the starting cost.
    @total_gain_loss = @total_market_value - @total_invested
    @gain_is_positive = @total_gain_loss > 0
    @gain_is_negative = @total_gain_loss < 0

    # Groups the top 5 largest investments by fund name for the charts.
    @recent_applications_chart = Application
                                   .joins(fund_investment: :investment_fund)
                                   .where(fund_investments: { portfolio_id: current_user.portfolios.select(:id) })
                                   .group("investment_funds.fund_name")
                                   .order("SUM(applications.financial_value) DESC")
                                   .limit(5)
                                   .sum(:financial_value)

    # Groups the top 5 largest withdrawals by fund name for the charts.
    @recent_redemptions_chart = Redemption
                                  .joins(fund_investment: :investment_fund)
                                  .where(fund_investments: { portfolio_id: current_user.portfolios.select(:id) })
                                  .group("investment_funds.fund_name")
                                  .order("SUM(redemptions.redeemed_liquid_value) DESC")
                                  .limit(5)
                                  .sum(:redeemed_liquid_value)

    @market_is_positive = @total_market_value > @total_invested
    @market_is_negative = @total_market_value < @total_invested

    # Calculates the percentage of profit or loss relative to the money invested.
    @roi = @total_invested > 0 ? ((@total_market_value - @total_invested) / @total_invested * 100) : 0
    @roi_positive = @roi > 0
    @roi_negative = @roi < 0

    # Counts how many different investment funds the user is currently using.
    @unique_funds = current_user.portfolios.flat_map do |portfolio|
      portfolio.fund_investments.map(&:investment_fund_id)
    end.uniq.count

    # Counts the total number of actions (buys and sells) ever recorded.
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
  #
  # This prepares the specific lists and numbers required to draw
  # pie charts and bar graphs. It organizes money flows by month so
  # users can see how their activity changes over time.
  def prepare_chart_data

    # Creates a map of portfolio names and their values for the allocation chart.
    @portfolio_allocation = {}
    current_user.portfolios.each do |portfolio|
      portfolio_value = portfolio.fund_investments.sum(:total_invested_value) || 0
      @portfolio_allocation[portfolio.name] = portfolio_value if portfolio_value > 0
    end

    @monthly_flows = {}

    # Accumulates all deposit values and groups them by month and year.
    applications = Application.joins(fund_investment: :portfolio)
                              .where(portfolios: { user_id: current_user.id })
                              .where.not(request_date: nil)

    applications.each do |app|
      month_key = app.request_date.strftime("%m/%Y")
      @monthly_flows[month_key] ||= { "Aplicações" => 0, "Resgates" => 0 }
      @monthly_flows[month_key]["Aplicações"] += app.financial_value || 0
    end

    # Accumulates all withdrawal values and groups them by month and year.
    redemptions = Redemption.joins(fund_investment: :portfolio)
                            .where(portfolios: { user_id: current_user.id })
                            .where.not(request_date: nil)

    redemptions.each do |red|
      month_key = red.request_date.strftime("%m/%Y")
      @monthly_flows[month_key] ||= { "Aplicações" => 0, "Resgates" => 0 }
      @monthly_flows[month_key]["Resgates"] += red.redeemed_liquid_value || 0
    end

    # Sorts the monthly results so the chart moves forward correctly in time.
    @monthly_flows = @monthly_flows.sort_by { |k, _v| Date.strptime(k, "%m/%Y") }.to_h
  end

  # == load_recent_activity
  #
  # @author Moisés Reis
  #
  # This finds the five most recent deposits and withdrawals so
  # the user can see their latest movements without searching.
  def load_recent_activity

    # Fetches the last 5 deposits including related fund and portfolio names.
    @recent_applications = Application.joins(fund_investment: :portfolio)
                                      .where(portfolios: { user_id: current_user.id })
                                      .includes(fund_investment: [:portfolio, :investment_fund])
                                      .order(request_date: :desc)
                                      .limit(5)

    # Fetches the last 5 withdrawals including related fund and portfolio names.
    @recent_redemptions = Redemption.joins(fund_investment: :portfolio)
                                    .where(portfolios: { user_id: current_user.id })
                                    .includes(fund_investment: [:portfolio, :investment_fund])
                                    .order(request_date: :desc)
                                    .limit(5)
  end
end