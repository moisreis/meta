class InvestmentFundArticlesController < ApplicationController
  before_action :set_investment_fund_article, only: %i[ show edit update destroy ]

  # GET /investment_fund_articles or /investment_fund_articles.json
  def index
    @investment_fund_articles = InvestmentFundArticle.all
  end

  # GET /investment_fund_articles/1 or /investment_fund_articles/1.json
  def show
  end

  # GET /investment_fund_articles/new
  def new
    @investment_fund_article = InvestmentFundArticle.new
  end

  # GET /investment_fund_articles/1/edit
  def edit
  end

  # POST /investment_fund_articles or /investment_fund_articles.json
  def create
    @investment_fund_article = InvestmentFundArticle.new(investment_fund_article_params)

    respond_to do |format|
      if @investment_fund_article.save
        format.html { redirect_to @investment_fund_article, notice: "Investment fund article was successfully created." }
        format.json { render :show, status: :created, location: @investment_fund_article }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @investment_fund_article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /investment_fund_articles/1 or /investment_fund_articles/1.json
  def update
    respond_to do |format|
      if @investment_fund_article.update(investment_fund_article_params)
        format.html { redirect_to @investment_fund_article, notice: "Investment fund article was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @investment_fund_article }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @investment_fund_article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /investment_fund_articles/1 or /investment_fund_articles/1.json
  def destroy
    @investment_fund_article.destroy!

    respond_to do |format|
      format.html { redirect_to investment_fund_articles_path, notice: "Investment fund article was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_investment_fund_article
      @investment_fund_article = InvestmentFundArticle.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def investment_fund_article_params
      params.fetch(:investment_fund_article, {})
    end
end
