class PortfoliosController < ApplicationController
  include PdfExportable
  include MonthlyReportable

  before_action :authenticate_user!
  before_action :set_portfolio, only: %i[show edit update destroy monthly_report run_calculations]

  def index
    base_scope =
      if current_user.admin?
        Portfolio.all
      else
        Portfolio.for_user(current_user)
      end

    @q = base_scope.ransack(params[:q])
    @total_items = Portfolio.count
    filtered_and_scoped_portfolios = @q.result(distinct: true)

    sort = params[:sort].presence || "id"
    direction = params[:direction].presence || "asc"
    sorted_portfolios = filtered_and_scoped_portfolios.order("#{sort} #{direction}")

    @models = sorted_portfolios.page(params[:page]).per(14)
    @portfolios = @models

    respond_to do |format|
      format.html
    end
  end

  def show

    @portfolio = Portfolio.for_user(current_user).find(params[:id])

    @allocation_data = @portfolio.fund_investments.includes(:investment_fund).map do |fi|
      [fi.investment_fund.fund_name, fi.percentage_allocation || 0]
    end

    @monthly_flows = calculate_monthly_flows(@portfolio)

    @reference_period = Date.current.end_of_month

    @recent_performance = @portfolio.performance_histories
                                    .where(period: @reference_period)
                                    .includes(fund_investment: :investment_fund)

    @institution_distribution = @portfolio.fund_investments
                                          .includes(:investment_fund)
                                          .group_by { |fi| fi.investment_fund.administrator_name }
                                          .map { |admin, investments| [admin, investments.sum { |fi| fi.percentage_allocation || 0 }] }

    @equity_evolution = @portfolio.value_timeline(12)

    @monthly_earnings_history = @portfolio.performance_histories
                                          .where('period > ?', 12.months.ago)
                                          .group_by { |ph| ph.period.beginning_of_month }
                                          .map { |date, phs| [date.strftime('%b/%y'), phs.sum(&:earnings)] }
                                          .sort_by { |date_str, _| Date.strptime(date_str, '%b/%y') }

    if @recent_performance.empty?
      latest_period = @portfolio.performance_histories.maximum(:period)
      if latest_period
        @reference_period = latest_period
        @recent_performance = @portfolio.performance_histories
                                        .where(period: @reference_period)
                                        .includes(fund_investment: :investment_fund)
      end
    end

    @recent_performance = @recent_performance.order('monthly_return DESC')

    @total_earnings = BigDecimal('0')
    @portfolio_return = BigDecimal('0')
    @portfolio_yearly_return = BigDecimal('0')
    @portfolio_12m_return = BigDecimal('0')

    if @recent_performance.any?
      @total_earnings = @recent_performance.sum(:earnings)

      weighted_return = BigDecimal('0')
      weighted_yearly = BigDecimal('0')
      weighted_12m = BigDecimal('0')
      total_allocation = BigDecimal('0')

      @recent_performance.each do |perf|
        allocation = perf.fund_investment.percentage_allocation || BigDecimal('0')
        total_allocation += allocation

        weighted_return += (perf.monthly_return || 0) * allocation
        weighted_yearly += (perf.yearly_return || 0) * allocation
        weighted_12m    += (perf.last_12_months_return || 0) * allocation
      end

      if total_allocation > 0
        @portfolio_return = weighted_return / total_allocation
        @portfolio_yearly_return = weighted_yearly / total_allocation
        @portfolio_12m_return = weighted_12m / total_allocation
      end
    end
  end

  def new
    @portfolio = Portfolio.new
  end

  def edit
  end

  def create
    @portfolio = Portfolio.new(portfolio_params.except(:shared_user_id))

    flash[:notice] = "Carteira criada com sucesso."

    respond_to do |format|
      if @portfolio.save
        shared_user_id = params.dig(:portfolio, :shared_user_id)
        permission_level = params.dig(:portfolio, :grant_crud_permission) || 'read'

        if shared_user_id.present?
          UserPortfolioPermission.create!(
            user_id: shared_user_id,
            portfolio_id: @portfolio.id,
            permission_level: permission_level
          )
        end
        format.html { redirect_to @portfolio, notice: "Portfolio was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @portfolio.update(portfolio_params.except(:shared_user_id))
        shared_user_id = params.dig(:portfolio, :shared_user_id)
        permission_level = params.dig(:portfolio, :grant_crud_permission) || 'read'

        if shared_user_id.present?
          UserPortfolioPermission.find_or_create_by!(
            user_id: shared_user_id,
            portfolio_id: @portfolio.id
          ) do |permission|
            permission.permission_level = permission_level
          end
        end
        format.html { redirect_to @portfolio, notice: "Portfolio was successfully updated.", status: :see_other }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @portfolio.destroy!

    flash[:notice] = "Carteira deletada com sucesso."

    respond_to do |format|
      format.html { redirect_to portfolios_path, notice: "Portfolio was successfully destroyed.", status: :see_other }
    end
  end

  def run_calculations

    PerformanceCalculationJob.perform_later

    redirect_to portfolio_path(@portfolio), notice: "Cálculo iniciado em segundo plano!"
  end

  private

  def pdf_export_title
    "Carteiras"
  end

  def pdf_export_subtitle
    "Lista de carteiras com permissão de visualização"
  end

  def pdf_export_columns
    [
      {
        header: "Nome",
        key: :name,
        width: 150
      },
      {
        header: "Proprietário",
        key: ->(portfolio) do
          user = portfolio.user
          user == current_user ? "Você" : user.full_name
        end,
        width: 120
      },
      {
        header: "Compartilhado com",
        key: ->(portfolio) do
          shared = portfolio.user_portfolio_permissions.includes(:user)
          if shared.any?
            shared.map { |p| p.user == current_user ? "Você" : p.user.full_name }.join(", ")
          else
            "N/A"
          end
        end,
        width: 150
      },
      {
        header: "Valor Investido",
        key: ->(portfolio) do
          ActionController::Base.helpers.number_to_currency(
            portfolio.total_invested_value,
            unit: "R$ ",
            separator: ",",
            delimiter: "."
          )
        end,
        width: 100
      },
      {
        header: "Cotas",
        key: ->(portfolio) do
          ActionController::Base.helpers.number_with_precision(
            portfolio.total_quotas_held,
            precision: 2,
            separator: ",",
            delimiter: "."
          )
        end,
        width: 100
      }
    ]
  end

  def pdf_export_data
    base_scope = if current_user.admin?
                   Portfolio.all
                 else
                   Portfolio.for_user(current_user)
                 end

    @q = base_scope.ransack(params[:q])
    @q.result(distinct: true)
  end

  def pdf_export_metadata
    {
      'Gerado por' => current_user.full_name,
    }
  end

  def calculate_monthly_flows(portfolio)
    monthly_data = []

    12.times do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = month_start.end_of_month
      month_label = month_start.strftime('%b/%Y')

      applications_sum = portfolio.fund_investments
                                  .joins(:applications)
                                  .where(applications: { cotization_date: month_start..month_end })
                                  .sum('applications.financial_value')

      redemptions_sum = portfolio.fund_investments
                                 .joins(:redemptions)
                                 .where(redemptions: { cotization_date: month_start..month_end })
                                 .sum('redemptions.redeemed_liquid_value')

      monthly_data << {
        month: month_label,
        applications: applications_sum,
        redemptions: redemptions_sum
      }
    end

    monthly_data.reverse!

    [
      { name: "Aplicações", data: monthly_data.map { |m| [m[:month], m[:applications]] } },
      { name: "Resgates", data: monthly_data.map { |m| [m[:month], m[:redemptions]] } }
    ]
  end

  def set_portfolio
    @portfolio = Portfolio.find(params[:id])
  end

  def portfolio_params
    params.require(:portfolio).permit(
      :name,
      :user_id,
      :shared_user_id
    )
  end
end