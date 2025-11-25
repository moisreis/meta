class CreateApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :applications do |t|
      t.references :fund_investment, null: false, foreign_key: true
      t.date :request_date
      t.date :cotization_date
      t.date :liquidation_date
      t.decimal :financial_value
      t.decimal :number_of_quotas
      t.decimal :quota_value_at_application
      t.timestamps
    end
  end
end
