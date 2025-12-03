class CreateFundValuations < ActiveRecord::Migration[8.1]
  create_table :fund_valuations, primary_key: [:date, :fund_cnpj] do |t|
    t.date :date, null: false
    t.string :fund_cnpj, null: false
    t.decimal :quota_value, precision: 15, scale: 6, null: false
    t.string :source
    t.text :other_public_information

    t.timestamps
  end

  add_foreign_key :fund_valuations, :investment_funds, column: :fund_cnpj, primary_key: :cnpj
end
