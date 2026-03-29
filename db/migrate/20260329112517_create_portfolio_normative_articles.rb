class CreatePortfolioNormativeArticles < ActiveRecord::Migration[8.1]
  def change
    create_table "public.portfolio_normative_articles" do |t|
      t.references :portfolio,         null: false, foreign_key: { to_table: "public.portfolios" }
      t.references :normative_article,  null: false, foreign_key: { to_table: "public.normative_articles" }
      t.decimal :benchmark_target, precision: 8, scale: 4
      t.decimal :minimum_target,   precision: 8, scale: 4
      t.decimal :maximum_target,   precision: 8, scale: 4
      t.timestamps
    end

    add_index "public.portfolio_normative_articles",
              [:portfolio_id, :normative_article_id],
              unique: true,
              name: "index_portfolio_normative_articles_uniqueness"
  end
end
