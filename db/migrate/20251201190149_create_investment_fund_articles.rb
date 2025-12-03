class CreateInvestmentFundArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :investment_fund_articles do |t|
      t.references :investment_fund, null: false, foreign_key: true
      t.references :normative_article, null: false, foreign_key: true
      t.string :note

      t.timestamps
    end
  end
end
