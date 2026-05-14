<%#
  VIEW: show.json.jbuilder
  ACTION: CheckingAccountsController#show
  DESCRIPTION: JSON detail of a single CheckingAccount.
  INSTANCE VARIABLES:
    - @checking_account: [CheckingAccount] The record to serialize.
%>
json.partial! "checking_accounts/checking_account", checking_account: @checking_account
