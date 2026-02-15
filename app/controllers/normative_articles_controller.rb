class NormativeArticlesController < ApplicationController

  before_action :authenticate_user!

  before_action :load_normative_article, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  before_action :authorize_normative_article, only: [
    :show,
    :update,
    :destroy
  ]

  def index

    base_scope = NormativeArticle.all.order(created_at: :desc)

    @q = base_scope.ransack(params[:q])

    filtered = @q.result(distinct: true)

    @total_items = NormativeArticle.count

    sort = params[:sort].presence || "created_at"

    direction = params[:direction].presence || "desc"

    sorted = filtered.order("#{sort} #{direction}")

    @normative_articles = sorted.page(params[:page]).per(14)

    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: 'Success',
          data: NormativeArticleSerializer.new(@normative_articles).serializable_hash
        }
      }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json {
        render json: {
          status: 'Success',
          data: NormativeArticleSerializer.new(@normative_article).serializable_hash[:data][:attributes]
        }
      }
    end
  end

  def new
    @normative_article = NormativeArticle.new

    authorize! :create, NormativeArticle
  rescue CanCan::AccessDenied => e
    redirect_to normative_articles_path, alert: e.message
  end

  def edit
  end

  def create
    @normative_article = NormativeArticle.new(normative_article_params)

    authorize! :create, NormativeArticle

    if @normative_article.save
      respond_to do |format|
        format.html {
          redirect_to normative_article_path(@normative_article),
                      notice: 'Normative article was successfully created.'
        }
        format.json {
          render json: {
            status: 'Success',
            data: NormativeArticleSerializer.new(@normative_article).serializable_hash[:data][:attributes]
          }, status: :created
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json {
          render json: {
            status: 'Error',
            errors: @normative_article.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end

  rescue CanCan::AccessDenied => e
    respond_to do |format|
      format.html { redirect_to normative_articles_path, alert: e.message }
      format.json {
        render json: {
          status: 'Error',
          message: e.message
        }, status: :forbidden
      }
    end
  end

  def update

    if @normative_article.update(normative_article_params)
      respond_to do |format|
        format.html {
          redirect_to normative_article_path(@normative_article),
                      notice: 'Normative article was successfully updated.'
        }
        format.json {
          render json: {
            status: 'Success',
            data: NormativeArticleSerializer.new(@normative_article).serializable_hash[:data][:attributes]
          }
        }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json {
          render json: {
            status: 'Error',
            errors: @normative_article.errors.full_messages
          }, status: :unprocessable_entity
        }
      end
    end
  end

  def destroy

    @normative_article.destroy!

    respond_to do |format|
      format.html {
        redirect_to normative_articles_path,
                    notice: 'Normative article was successfully deleted.',
                    status: :see_other
      }
      format.json {
        render json: {
          status: 'Success',
          message: 'Normative article deleted successfully'
        }, status: :ok
      }
    end

  rescue ActiveRecord::RecordNotDestroyed => e
    respond_to do |format|
      format.html {
        redirect_to normative_article_path(@normative_article),
                    alert: 'Failed to delete normative article'
      }
      format.json {
        render json: {
          status: 'Error',
          message: 'Failed to delete normative article',
          errors: e.record.errors.full_messages
        }, status: :unprocessable_entity
      }
    end

  rescue ActiveRecord::RecordNotFound => e
    respond_to do |format|
      format.html { redirect_to normative_articles_path, alert: 'Normative article not found' }
      format.json {
        render json: {
          status: 'Error',
          message: "Normative article not found: #{e.message}"
        }, status: :not_found
      }
    end

  rescue CanCan::AccessDenied => e
    respond_to do |format|
      format.html { redirect_to normative_articles_path, alert: e.message }
      format.json {
        render json: {
          status: 'Error',
          message: e.message
        }, status: :forbidden
      }
    end
  end

  private

  def load_normative_article
    @normative_article = NormativeArticle.find(params[:id])
  end

  def authorize_normative_article

    authorize! :read, @normative_article if action_name == 'show'

    authorize! :manage, @normative_article if %w[update destroy].include?(action_name)
  end

  def normative_article_params
    params.require(:normative_article).permit(
      :article_name,
      :article_number,
      :article_body,
      :description,
      :benchmark_target
    )
  end
end