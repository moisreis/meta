class CreatePerformanceHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :performance_histories do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.references :fund_investment, null: false, foreign_key: true
      t.date :period
      t.decimal :monthly_return
      t.decimal :yearly_return
      t.decimal :last_12_months_return

      t.timestamps
    end
  end
end
