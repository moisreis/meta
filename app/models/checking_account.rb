# === checking_account
#
# @author Moisés Reis
# @added 02/22/2026
# @package *Meta*
# @description Representa o saldo mensal de uma conta corrente vinculada a um **Portfolio**.
#              Permite que o sistema inclua disponibilidades (caixa bancário) no patrimônio
#              total do carteira, tanto nos cálculos de rentabilidade quanto nos relatórios.
# @category *Model*
#
# Usage:: - *[What]* Armazena o saldo de uma conta bancária em um mês de referência.
#         - *[How]* Vinculada ao carteira via FK, com validações de saldo e data.
#         - *[Why]* O patrimônio de um RPPS não se resume a fundos; o caixa disponível
#           em conta corrente também deve ser contabilizado e reportado.
#
# Attributes:: - *portfolio_id*    @integer - FK para o carteira dono desta conta
#              - *name*            @string  - nome/descrição da conta (ex: "CC Bradesco")
#              - *institution*     @string  - instituição financeira
#              - *account_number*  @string  - número da conta (opcional)
#              - *balance*         @decimal - saldo na data de referência
#              - *reference_date*  @date    - último dia do mês de competência
#              - *currency*        @string  - moeda (padrão BRL)
#              - *notes*           @text    - observações livres
#
class CheckingAccount < ApplicationRecord

  # Explanation:: Cada conta corrente pertence a exatamente um carteira.
  belongs_to :portfolio

  # Explanation:: Valida que o carteira esteja sempre presente.
  validates :portfolio_id, presence: true

  # Explanation:: O nome da conta é obrigatório e deve ter entre 2 e 100 caracteres.
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  # Explanation:: O saldo é obrigatório e deve ser maior ou igual a zero.
  #               Contas correntes não registram saldo negativo neste contexto.
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Explanation:: A data de referência é obrigatória — identifica o mês do saldo.
  validates :reference_date, presence: true

  # Explanation:: A moeda tem um valor padrão mas deve ser informada.
  validates :currency, presence: true, length: { maximum: 3 }

  # Explanation:: Limita campos opcionais para não poluir o banco.
  validates :institution,    length: { maximum: 100 }, allow_blank: true
  validates :account_number, length: { maximum: 50  }, allow_blank: true
  validates :notes,          length: { maximum: 500  }, allow_blank: true

  # Explanation:: Impede registros com data futura — não podemos saber saldos futuros.
  validate :reference_date_not_in_future

  # Explanation:: Garante que não existam dois saldos do mesmo nome para o mesmo mês
  #               no mesmo carteira.
  validates :name, uniqueness: {
    scope: [:portfolio_id, :reference_date],
    message: "já existe uma conta com este nome para esta carteira neste mês"
  }

  # Scopes ─────────────────────────────────────────────────────────────────────

  # Explanation:: Facilita buscar contas de um carteira em um mês específico.
  scope :for_period,    ->(date)      { where(reference_date: date) }

  # Explanation:: Retorna contas dentro de um intervalo de datas.
  scope :in_range,      ->(from, to)  { where(reference_date: from..to) }

  # Explanation:: Ordena por data crescente para facilitar histórico.
  scope :by_date,       ->            { order(:reference_date) }

  # Explanation:: Filtra por instituição financeira.
  scope :by_institution, ->(inst)     { where(institution: inst) }

  # Instance methods ────────────────────────────────────────────────────────────

  # == identifier
  #
  # @category *Display*
  # Retorna uma string legível identificando a conta e o mês.
  #
  def identifier
    "#{name} — #{reference_date&.strftime('%b/%Y')}"
  end

  # == institution_label
  #
  # @category *Display*
  # Retorna o nome da instituição ou um fallback legível.
  #
  def institution_label
    institution.presence || "Instituição não informada"
  end

  # Class methods ───────────────────────────────────────────────────────────────

  # == total_balance_for
  #
  # @category *Aggregation*
  # Calcula o saldo total de todas as contas de um carteira em um mês.
  #
  def self.total_balance_for(portfolio, date)
    where(portfolio: portfolio, reference_date: date).sum(:balance)
  end

  # == ransackable_attributes
  def self.ransackable_attributes(auth_object = nil)
    %w[account_number balance created_at currency id institution name notes
       portfolio_id reference_date updated_at]
  end

  # == ransackable_associations
  def self.ransackable_associations(auth_object = nil)
    %w[portfolio]
  end

  private

  def reference_date_not_in_future
    return unless reference_date
    errors.add(:reference_date, "não pode ser uma data futura") if reference_date > Date.current
  end
end