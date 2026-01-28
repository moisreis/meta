# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_07_185948) do
  create_schema "extensions"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "public.applications", force: :cascade do |t|
    t.date "cotization_date"
    t.datetime "created_at", null: false
    t.decimal "financial_value"
    t.bigint "fund_investment_id", null: false
    t.date "liquidation_date"
    t.decimal "number_of_quotas"
    t.decimal "quota_value_at_application"
    t.date "request_date"
    t.datetime "updated_at", null: false
    t.index ["fund_investment_id"], name: "index_applications_on_fund_investment_id"
  end

  create_table "public.economic_index_histories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.bigint "economic_index_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "value"
    t.index ["economic_index_id"], name: "index_economic_index_histories_on_economic_index_id"
  end

  create_table "public.economic_indices", force: :cascade do |t|
    t.string "abbreviation", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["abbreviation"], name: "index_economic_indices_on_abbreviation", unique: true
    t.index ["name"], name: "index_economic_indices_on_name", unique: true
  end

  create_table "public.fund_investments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "investment_fund_id", null: false
    t.decimal "percentage_allocation"
    t.bigint "portfolio_id", null: false
    t.decimal "total_invested_value"
    t.decimal "total_quotas_held"
    t.datetime "updated_at", null: false
    t.index ["investment_fund_id"], name: "index_fund_investments_on_investment_fund_id"
    t.index ["portfolio_id"], name: "index_fund_investments_on_portfolio_id"
  end

  create_table "public.fund_valuations", primary_key: ["date", "fund_cnpj"], force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "fund_cnpj", null: false
    t.text "other_public_information"
    t.decimal "quota_value", precision: 15, scale: 6, null: false
    t.string "source"
    t.datetime "updated_at", null: false
  end

  create_table "public.investment_fund_articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "investment_fund_id", null: false
    t.bigint "normative_article_id", null: false
    t.string "note"
    t.datetime "updated_at", null: false
    t.index ["investment_fund_id"], name: "index_investment_fund_articles_on_investment_fund_id"
    t.index ["normative_article_id"], name: "index_investment_fund_articles_on_normative_article_id"
  end

  create_table "public.investment_funds", force: :cascade do |t|
    t.string "administrator_name", null: false
    t.string "cnpj", null: false
    t.datetime "created_at", null: false
    t.string "fund_name", null: false
    t.string "originator_fund"
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "index_investment_funds_on_cnpj", unique: true
    t.index ["fund_name"], name: "index_investment_funds_on_fund_name"
  end

  create_table "public.normative_articles", force: :cascade do |t|
    t.string "article_body"
    t.string "article_name"
    t.string "article_number"
    t.decimal "benchmark_target"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "updated_at", null: false
  end

  create_table "public.performance_histories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "earnings"
    t.bigint "fund_investment_id", null: false
    t.decimal "last_12_months_return"
    t.decimal "monthly_return"
    t.date "period"
    t.bigint "portfolio_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "yearly_return"
    t.index ["fund_investment_id"], name: "index_performance_histories_on_fund_investment_id"
    t.index ["portfolio_id"], name: "index_performance_histories_on_portfolio_id"
  end

  create_table "public.portfolios", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "public.redemption_allocations", force: :cascade do |t|
    t.bigint "application_id", null: false
    t.datetime "created_at", null: false
    t.decimal "quotas_used"
    t.bigint "redemption_id", null: false
    t.datetime "updated_at", null: false
    t.index ["application_id"], name: "index_redemption_allocations_on_application_id"
    t.index ["redemption_id"], name: "index_redemption_allocations_on_redemption_id"
  end

  create_table "public.redemptions", force: :cascade do |t|
    t.date "cotization_date"
    t.datetime "created_at", null: false
    t.bigint "fund_investment_id", null: false
    t.date "liquidation_date"
    t.decimal "redeemed_liquid_value"
    t.decimal "redeemed_quotas"
    t.string "redemption_type"
    t.decimal "redemption_yield"
    t.date "request_date"
    t.datetime "updated_at", null: false
    t.index ["fund_investment_id"], name: "index_redemptions_on_fund_investment_id"
  end

  create_table "public.user_portfolio_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "permission_level"
    t.bigint "portfolio_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["portfolio_id"], name: "index_user_portfolio_permissions_on_portfolio_id"
    t.index ["user_id"], name: "index_user_portfolio_permissions_on_user_id"
  end

  create_table "public.users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "public.applications", "public.fund_investments"
  add_foreign_key "public.economic_index_histories", "public.economic_indices"
  add_foreign_key "public.fund_investments", "public.investment_funds"
  add_foreign_key "public.fund_investments", "public.portfolios"
  add_foreign_key "public.fund_valuations", "public.investment_funds", column: "fund_cnpj", primary_key: "cnpj"
  add_foreign_key "public.investment_fund_articles", "public.investment_funds"
  add_foreign_key "public.investment_fund_articles", "public.normative_articles"
  add_foreign_key "public.performance_histories", "public.fund_investments"
  add_foreign_key "public.performance_histories", "public.portfolios"
  add_foreign_key "public.portfolios", "public.users"
  add_foreign_key "public.redemption_allocations", "public.applications"
  add_foreign_key "public.redemption_allocations", "public.redemptions"
  add_foreign_key "public.redemptions", "public.fund_investments"
  add_foreign_key "public.user_portfolio_permissions", "public.portfolios"
  add_foreign_key "public.user_portfolio_permissions", "public.users"

end
