class CreateNormativeArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :normative_articles do |t|
      t.string :article_name
      t.string :article_number
      t.string :article_body
      t.text :description
      t.decimal :benchmark_target

      t.timestamps
    end
  end
end
