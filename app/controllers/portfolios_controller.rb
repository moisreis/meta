# === portfolios_controller
#
# @author Moisés Reis
# @updated 01/02/2026 - Added PDF export functionality
# @package Meta
# @description This controller manages a user's Portfolio records, handling the
#              listing, creation, modification, deletion, and PDF export.
# @category Controller

class PortfoliosController < ApplicationController
  include PdfExportable

  before_action :authenticate_user!
  before_action :set_portfolio, only: %i[ show edit update destroy ]

  # == index
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

  # == show
  # == show
  def show
    @portfolio = Portfolio.for_user(current_user).find(params[:id])

    # Dados de alocação (gráfico de pizza)
    @allocation_data = @portfolio.fund_investments.includes(:investment_fund).map do |fi|
      [fi.investment_fund.fund_name, fi.percentage_allocation || 0]
    end

    # Dados de transações (gráfico de linha)
    @monthly_flows = calculate_monthly_flows(@portfolio)

    # ================================================================
    # DADOS DE PERFORMANCE
    # ================================================================

    # Busca o período mais recente com dados de performance
    # Tenta o mês atual primeiro, senão pega o mais recente disponível
    @reference_period = Date.current.end_of_month

    # Performance de cada fundo no período
    @recent_performance = @portfolio.performance_histories
                                    .where(period: @reference_period)
                                    .includes(fund_investment: :investment_fund)
                                    .order('monthly_return DESC')

    # Se não tem dados para o mês atual, pega o período mais recente
    if @recent_performance.empty?
      latest_period = @portfolio.performance_histories.maximum(:period)
      if latest_period
        @reference_period = latest_period
        @recent_performance = @portfolio.performance_histories
                                        .where(period: @reference_period)
                                        .includes(fund_investment: :investment_fund)
                                        .order('monthly_return DESC')
      end
    end

    # Cálculos dos totais da carteira
    if @recent_performance.any?
      # Rendimento Total = soma dos rendimentos de todos os fundos
      @total_earnings = @recent_performance.sum(:earnings)

      # Rentabilidade da Carteira = (Rendimento Total / Valor Investido) * 100
      @portfolio_return = if @portfolio.total_invested_value > 0
                            (@total_earnings / @portfolio.total_invested_value) * 100
                          else
                            0
                          end
    else
      @total_earnings = 0
      @portfolio_return = 0
    end
  end

  # == new
  def new
    @portfolio = Portfolio.new
  end

  # == edit
  def edit
  end

  # == create
  def create
    @portfolio = Portfolio.new(portfolio_params.except(:shared_user_id))

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

  # == update
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

  # == destroy
  def destroy
    @portfolio.destroy!
    respond_to do |format|
      format.html { redirect_to portfolios_path, notice: "Portfolio was successfully destroyed.", status: :see_other }
    end
  end

  private

  # == PDF Export Configuration Methods
  #
  # These methods configure the PDF export functionality provided by PdfExportable

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
    # Explanation:: Use the same scope and filters as the index action
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
      # 'E-mail' => current_user.email,
      # 'Total de carteiras' => pdf_export_data.size.to_s
    }
  end

  # == Original Private Methods

  def calculate_monthly_flows(portfolio)
    monthly_data = []

    12.times do |i|
      month_start = i.months.ago.beginning_of_month
      month_end = month_start.end_of_month
      month_label = month_start.strftime('%b/%y')

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