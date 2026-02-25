class AddFeesToInvestmentFunds < ActiveRecord::Migration[8.1]
  def change
    add_column :investment_funds, :administration_fee, :decimal, precision: 8, scale: 4, default: nil, comment: "Taxa de administração anual em percentual (ex: 0.5000 = 0,50% a.a.)"
    add_column :investment_funds, :performance_fee,    :decimal, precision: 8, scale: 4, default: nil, comment: "Taxa de performance em percentual (ex: 20.0000 = 20,00% sobre o que exceder o benchmark)"
  end
end