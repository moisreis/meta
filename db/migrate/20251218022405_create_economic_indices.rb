class CreateEconomicIndices < ActiveRecord::Migration[8.1]
  def change
    create_table :economic_indices do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :abbreviation, null: false, index: { unique: true }
      t.text :description

      t.timestamps
    end
  end
end
