class CreateEconomicIndexHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :economic_index_histories do |t|
      t.date :date
      t.references :economic_index, null: false, foreign_key: true
      t.decimal :value

      t.timestamps
    end
  end
end
