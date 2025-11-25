class CreateInvestmentFunds < ActiveRecord::Migration[8.1]
  def change

    create_table :investment_funds do |t|
      t.string :cnpj, null: false, index: { unique: true }
      t.string :fund_name, null: false
      t.string :originator_fund
      t.string :administrator_name, null: false

      t.timestamps
    end

    add_index :investment_funds, :fund_name
  end
end