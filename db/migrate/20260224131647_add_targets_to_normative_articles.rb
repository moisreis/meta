class AddTargetsToNormativeArticles < ActiveRecord::Migration[8.1]
  def change
    # migration
    add_column :normative_articles, :minimum_target, :decimal, precision: 8, scale: 4
    add_column :normative_articles, :maximum_target, :decimal, precision: 8, scale: 4
  end
end
