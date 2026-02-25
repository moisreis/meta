class CreateCheckingAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table "public.checking_accounts" do |t|
      t.bigint   "portfolio_id",   null: false
      t.string   "name",           null: false
      t.string   "institution"
      t.string   "account_number"
      t.decimal  "balance",        precision: 15, scale: 2, null: false, default: "0"
      t.date     "reference_date", null: false
      t.string   "currency",       default: "BRL", null: false
      t.text     "notes"
      t.datetime "created_at",     null: false
      t.datetime "updated_at",     null: false

      t.index ["portfolio_id"], name: "index_checking_accounts_on_portfolio_id"
      t.index ["portfolio_id", "reference_date"], name: "index_checking_accounts_on_portfolio_and_date"
    end

    add_foreign_key "public.checking_accounts", "public.portfolios"
  end
end