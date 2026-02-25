class AddBenchmarkIndexToInvestmentFunds < ActiveRecord::Migration[8.1]
  def change
    add_column :investment_funds, :benchmark_index, :string
  end
end
