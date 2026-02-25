# === checking_accounts_controller
#
# @author Moisés Reis
# @added 02/22/2026
# @package *Controllers*
# @description Gerencia as operações CRUD de **CheckingAccount** dentro do contexto
#              de um **Portfolio**. Segue o padrão nested resource:
#              /portfolios/:portfolio_id/checking_accounts
# @category *Controller*
#
# Usage:: - *[What]* Permite criar, listar, editar e remover contas correntes
#           vinculadas a um portfólio específico.
#         - *[How]* Escopado ao portfólio, usando o mesmo padrão de autorização
#                   do PortfoliosController: for_user para leitura, verificação
#                   direta de user_id para escrita.
#         - *[Why]* As disponibilidades em conta corrente precisam ser registradas
#           mensalmente para compor o patrimônio total do portfólio no relatório.
#
class CheckingAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_portfolio
  before_action :authorize_write!, only: %i[new create edit update destroy]
  before_action :set_checking_account, only: %i[show edit update destroy]

  # GET /portfolios/:portfolio_id/checking_accounts
  #
  # Lista todas as contas correntes do portfólio para o mês de referência.
  # Filtro por `?month=YYYY-MM`; usa o mês corrente como fallback.
  #
  def index
    @reference_date = parse_reference_date(params[:month])

    @q = @portfolio.checking_accounts
                   .for_period(@reference_date.end_of_month)
                   .ransack(params[:q])

    @checking_accounts = @q.result
                           .order(:institution, :name)
                           .page(params[:page]).per(14)

    @total_balance = @portfolio.checking_accounts
                               .for_period(@reference_date.end_of_month)
                               .sum(:balance)

    @available_months = @portfolio.checking_accounts
                                  .distinct
                                  .order(reference_date: :desc)
                                  .limit(24)
                                  .pluck(:reference_date)

    respond_to do |format|
      format.html
    end
  end

  # GET /portfolios/:portfolio_id/checking_accounts/:id
  def show
  end

  # GET /portfolios/:portfolio_id/checking_accounts/new
  #
  # Inicializa um novo registro com mês de referência e moeda padrão.
  #
  def new
    @checking_account = @portfolio.checking_accounts.new(
      reference_date: Date.current.end_of_month,
      currency: 'BRL'
    )
  end

  # GET /portfolios/:portfolio_id/checking_accounts/:id/edit
  def edit
  end

  # POST /portfolios/:portfolio_id/checking_accounts
  def create
    @checking_account = @portfolio.checking_accounts.new(checking_account_params)

    respond_to do |format|
      if @checking_account.save
        format.html do
          redirect_to portfolio_checking_accounts_path(
                        @portfolio,
                        month: @checking_account.reference_date.strftime('%Y-%m')
                      ),
                      notice: "Conta corrente \"#{@checking_account.name}\" criada com sucesso."
        end
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /portfolios/:portfolio_id/checking_accounts/:id
  def update
    respond_to do |format|
      if @checking_account.update(checking_account_params)
        format.html do
          redirect_to portfolio_checking_account_path(@portfolio, @checking_account),
                      notice: "Conta corrente \"#{@checking_account.name}\" atualizada com sucesso.",
                      status: :see_other
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /portfolios/:portfolio_id/checking_accounts/:id
  def destroy
    month_param = @checking_account.reference_date.strftime('%Y-%m')
    @checking_account.destroy!

    respond_to do |format|
      format.html do
        redirect_to portfolio_checking_accounts_path(@portfolio, month: month_param),
                    notice: "Conta corrente removida com sucesso.",
                    status: :see_other
      end
    end
  end

  private

  # == set_portfolio
  #
  # Usa o mesmo padrão do PortfoliosController#show:
  # `for_user` para usuários comuns (left_joins, sem conflito de estrutura no .or),
  # acesso irrestrito para admins.
  #
  def set_portfolio
    base_scope = current_user.admin? ? Portfolio.all : Portfolio.for_user(current_user)
    @portfolio = base_scope.find(params[:portfolio_id])
  end

  # == authorize_write!
  #
  # Ações de escrita exigem que o usuário seja dono do portfólio ou admin.
  # Usuários com permissão compartilhada são somente-leitura por padrão,
  # a menos que sejam admin.
  #
  def authorize_write!
    return if current_user.admin?
    return if @portfolio.user_id == current_user.id

    redirect_to portfolio_checking_accounts_path(@portfolio),
                alert: "Você não tem permissão para modificar as contas correntes desta carteira."
  end

  # == set_checking_account
  #
  # Sempre escopado ao portfólio para garantir isolamento entre portfólios.
  #
  def set_checking_account
    @checking_account = @portfolio.checking_accounts.find(params[:id])
  end

  # == checking_account_params
  #
  # Normaliza a `reference_date` para o último dia do mês antes de persistir.
  #
  def checking_account_params
    permitted = params.require(:checking_account).permit(
      :name,
      :institution,
      :account_number,
      :balance,
      :reference_date,
      :currency,
      :notes
    )

    if permitted[:reference_date].present?
      begin
        permitted[:reference_date] = Date.parse(permitted[:reference_date].to_s).end_of_month
      rescue Date::Error
        # Deixa a validação do model lidar com valor inválido
      end
    end

    permitted
  end

  # == parse_reference_date
  #
  # Converte `?month=YYYY-MM` em Date apontando para o último dia do mês.
  # Fallback: último dia do mês corrente.
  #
  def parse_reference_date(month_param)
    return Date.current.end_of_month if month_param.blank?

    Date.strptime("#{month_param}-01", '%Y-%m-%d').end_of_month
  rescue Date::Error
    Date.current.end_of_month
  end
end
