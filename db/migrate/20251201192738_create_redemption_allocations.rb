class CreateRedemptionAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :redemption_allocations do |t|
      t.references :redemption, null: false, foreign_key: true
      t.references :application, null: false, foreign_key: true
      t.decimal :quotas_used

      t.timestamps
    end
  end
end
