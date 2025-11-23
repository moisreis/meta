class CreateUserPortfolioPermissions < ActiveRecord::Migration[8.0]
  def change

    create_table :user_portfolio_permissions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :portfolio, null: false, foreign_key: true
      t.string :permission_level

      t.timestamps
    end
  end
end