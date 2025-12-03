class NormativeArticlesController < ApplicationController
  before_action :set_normative_article, only: %i[ show edit update destroy ]

  # GET /normative_articles or /normative_articles.json
  def index
    @normative_articles = NormativeArticle.all
  end

  # GET /normative_articles/1 or /normative_articles/1.json
  def show
  end

  # GET /normative_articles/new
  def new
    @normative_article = NormativeArticle.new
  end

  # GET /normative_articles/1/edit
  def edit
  end

  # POST /normative_articles or /normative_articles.json
  def create
    @normative_article = NormativeArticle.new(normative_article_params)

    respond_to do |format|
      if @normative_article.save
        format.html { redirect_to @normative_article, notice: "Normative article was successfully created." }
        format.json { render :show, status: :created, location: @normative_article }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @normative_article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /normative_articles/1 or /normative_articles/1.json
  def update
    respond_to do |format|
      if @normative_article.update(normative_article_params)
        format.html { redirect_to @normative_article, notice: "Normative article was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @normative_article }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @normative_article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /normative_articles/1 or /normative_articles/1.json
  def destroy
    @normative_article.destroy!

    respond_to do |format|
      format.html { redirect_to normative_articles_path, notice: "Normative article was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_normative_article
      @normative_article = NormativeArticle.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def normative_article_params
      params.fetch(:normative_article, {})
    end
end
