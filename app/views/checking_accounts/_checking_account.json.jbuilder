<%#
  PARTIAL: _checking_account.json.jbuilder
  DESCRIPTION: JSON partial for a single CheckingAccount record.
               Exposes id, timestamps, and a direct URL.
  LOCAL VARIABLES:
    - checking_account: [CheckingAccount] The record to serialize.
%>
json.extract! checking_account, :id, :created_at, :updated_at
json.url checking_account_url(checking_account, format: :json)
