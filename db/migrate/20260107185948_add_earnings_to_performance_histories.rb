class AddEarningsToPerformanceHistories < ActiveRecord::Migration[8.1]
  def change
    add_column :performance_histories, :earnings, :decimal
  end
end
