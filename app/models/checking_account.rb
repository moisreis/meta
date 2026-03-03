# === checking_account.rb
#
# @author Moisés Reis
# @added 02/22/2026
# @package *Meta*
# @description This model represents the monthly balance of a checking account linked
#              to a **Portfolio**. It allows the system to include liquid cash
#              in the total assets of the portfolio for performance and reports.
# @category *Model*
#
# Usage:: - *[What]* It stores the balance of a bank account for a specific reference month.
#         - *[How]* Linked to the portfolio via a foreign key with balance and date validations.
#         - *[Why]* Assets are not just funds; bank cash must also be accounted for
#                   to provide a complete financial overview.
#
# Attributes:: - *[portfolio_id]* @integer - the foreign key for the portfolio owning this account
#              - *[name]* @string - name or description of the account (e.g., "Bradesco Checking")
#              - *[institution]* @string - the financial institution name
#              - *[account_number]* @string - the optional account identification number
#              - *[balance]* @decimal - the balance amount on the reference date
#              - *[reference_date]* @date - the last day of the competence month
#              - *[currency]* @string - the currency type (defaults to BRL)
#              - *[notes]* @text - free-form observations or additional details
#
class CheckingAccount < ApplicationRecord

  # Each checking account belongs to exactly one portfolio, ensuring that
  # the cash is correctly attributed to the right investment collection.
  belongs_to :portfolio

  # Validates that a portfolio is always associated with the account.
  validates :portfolio_id, presence: true

  # The account name is mandatory and must have between 2 and 100 characters.
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  # The balance is required and must be zero or higher, as checking accounts
  # do not record negative balances in this specific financial context.
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # The reference date is mandatory because it identifies the specific month
  # that this balance snapshot represents.
  validates :reference_date, presence: true

  # The currency must be present and uses a short code format.
  validates :currency, presence: true, length: { maximum: 3 }

  # Limits optional fields to prevent the database from being cluttered.
  validates :institution, length: { maximum: 100 }, allow_blank: true
  validates :account_number, length: { maximum: 50 }, allow_blank: true
  validates :notes, length: { maximum: 500 }, allow_blank: true

  # Prevents saving a balance for a future date, as the system only
  # tracks confirmed historical or current data.
  validate :reference_date_not_in_future

  # Ensures that no two balances with the same name exist for the same month
  # within the same portfolio to avoid duplicate entries.
  validates :name, uniqueness: {
    scope: [:portfolio_id, :reference_date],
    message: "already exists for this portfolio in the selected month"
  }

  # Facilitates searching for accounts within a portfolio for a specific month.
  scope :for_period, ->(date) { where(reference_date: date) }

  # Retrieves accounts that fall within a specific start and end date.
  scope :in_range, ->(from, to) { where(reference_date: from..to) }

  # Orders the records by date to make history logs easier to read.
  scope :by_date, -> { order(:reference_date) }

  # Filters the records to show only those from a specific bank.
  scope :by_institution, ->(inst) { where(institution: inst) }

  # == identifier
  #
  # @author Moisés Reis
  #
  # Returns a readable string that identifies the account name
  # along with the formatted month and year.
  #
  def identifier
    "#{name} — #{reference_date&.strftime('%b/%Y')}"
  end

  # == institution_label
  #
  # @author Moisés Reis
  #
  # Returns the name of the bank or a simple fallback message
  # if the institution field was left blank.
  #
  def institution_label
    institution.presence || "Institution not informed"
  end

  # == total_balance_for
  #
  # @author Moisés Reis
  #
  # Calculates the total sum of all account balances for a specific
  # portfolio on a given reference date.
  #
  # Attributes:: - *@portfolio* - the portfolio to sum values for.
  #              - *@date* - the reference date for the calculation.
  #
  def self.total_balance_for(portfolio, date)
    where(portfolio: portfolio, reference_date: date).sum(:balance)
  end

  # == ransackable_attributes
  #
  # @author Moisés Reis
  #
  # Defines which database columns are safe to be used in
  # the search and filtering forms of the application.
  #
  def self.ransackable_attributes(auth_object = nil)
    %w[account_number balance created_at currency id institution name notes
       portfolio_id reference_date updated_at]
  end

  # == ransackable_associations
  #
  # @author Moisés Reis
  #
  # Defines which related models can be searched through the
  # checking account interface, such as the portfolio name.
  #
  def self.ransackable_associations(auth_object = nil)
    %w[portfolio]
  end

  private

  # == reference_date_not_in_future
  #
  # @author Moisés Reis
  #
  # Verifies if the chosen date is in the future. If it is, it adds
  # an error message to prevent the record from being saved.
  #
  def reference_date_not_in_future
    return unless reference_date
    errors.add(:reference_date, "cannot be a future date") if reference_date > Date.current
  end
end