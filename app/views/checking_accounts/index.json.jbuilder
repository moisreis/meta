<%#
  VIEW: index.json.jbuilder
  ACTION: CheckingAccountsController#index
  DESCRIPTION: JSON collection of checking accounts.
  INSTANCE VARIABLES:
    - @checking_accounts: [Array<CheckingAccount>] The collection to serialize.
%>
json.array! @checking_accounts, partial: "checking_accounts/checking_account", as: :checking_account
