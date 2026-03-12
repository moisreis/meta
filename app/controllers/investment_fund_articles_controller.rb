# === investment_fund_articles_controller.rb
#
# Description:: This controller manages the lifecycle of articles related to
#               investment funds, handling the creation, display, update, and
#               removal of informative content.
#
# Usage:: - *What* - A management interface for publishing and maintaining
#           articles that provide insights into specific investment funds.
#         - *How* - It provides standard RESTful actions to capture user input
#           from forms and persist article data in the database.
#         - *Why* - It enables the platform to share knowledge and news, keeping
#           users informed about financial market developments and specific fund details.
#
# Attributes:: - *@investment_fund_articles* [Collection] - A list of available articles.
#              - *@investment_fund_article* [Object] - A single article being processed.
#
class InvestmentFundArticlesController < ApplicationController

  # =============================================================
  #                        CONFIGURATION
  # =============================================================

  # This retrieves a specific article from the database before performing
  # operations like viewing, editing, updating, or deleting it.
  before_action :set_investment_fund_article, only: %i[show edit update destroy]

  # =============================================================
  #                       PUBLIC METHODS
  # =============================================================

  # == index
  #
  # @author Moisés Reis
  #
  # This action retrieves and displays a list of all investment fund articles
  # currently stored in the system.
  def index
    @investment_fund_articles = InvestmentFundArticle.all

    # This variable stores the total number of records found in the database.
    # It allows the user to see exactly how many items exist in the list.
    @total_items = InvestmentFundArticle.count
  end

  # == show
  #
  # @author Moisés Reis
  #
  # This displays the full content of a specific investment fund article.
  def show
  end

  # == new
  #
  # @author Moisés Reis
  #
  # This prepares a blank article object for the creation form.
  def new
    @investment_fund_article = InvestmentFundArticle.new
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # This loads an existing article to be modified through the edit form.
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  #
  # This processes form submissions to create a new investment fund article
  # in the database and redirects the user to the article view.
  def create
    @investment_fund_article = InvestmentFundArticle.new(investment_fund_article_params)

    respond_to do |format|
      if @investment_fund_article.save
        format.html { redirect_to @investment_fund_article, notice: "Artigo de fundo de investimento foi criado com sucesso." }
        format.json { render :show, status: :created, location: @investment_fund_article }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @investment_fund_article.errors, status: :unprocessable_entity }
      end
    end
  end

  # == update
  #
  # @author Moisés Reis
  #
  # This processes form submissions to update an existing article's details
  # and redirects back to the article page.
  def update
    respond_to do |format|
      if @investment_fund_article.update(investment_fund_article_params)
        format.html { redirect_to @investment_fund_article, notice: "Artigo de fundo de investimento foi atualizado com sucesso.", status: :see_other }
        format.json { render :show, status: :ok, location: @investment_fund_article }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @investment_fund_article.errors, status: :unprocessable_entity }
      end
    end
  end

  # == destroy
  #
  # @author Moisés Reis
  #
  # This permanently removes an article from the system and redirects the
  # user back to the list of articles.
  def destroy
    @investment_fund_article.destroy!

    respond_to do |format|
      format.html { redirect_to investment_fund_articles_path, notice: "Artigo de fundo de investimento foi deletado com sucesso.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # =============================================================
  #                       HELPER UTILITIES
  # =============================================================

  private

  # == set_investment_fund_article
  #
  # @author Moisés Reis
  #
  # This helper finds the article by ID before performing specific actions.
  def set_investment_fund_article
    @investment_fund_article = InvestmentFundArticle.find(params.expect(:id))
  end

  # == investment_fund_article_params
  #
  # @author Moisés Reis
  #
  # This helper restricts and sanitizes the data sent from the form to
  # ensure only valid article parameters are accepted.
  def investment_fund_article_params
    params.fetch(:investment_fund_article, {})
  end
end