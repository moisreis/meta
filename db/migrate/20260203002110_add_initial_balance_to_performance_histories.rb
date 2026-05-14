class AddInitialBalanceToPerformanceHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :performance_histories, :initial_balance, :decimal, precision: 15, scale: 2
    add_index :performance_histories, :initial_balance
  end
end
