# === normative_articles_controller.rb
#
# Description:: Manages the administration of normative articles, providing
#               full CRUD capabilities to define regulatory benchmarks and
#               rules within the system.
#
# Usage:: - *What* - A management interface for defining and maintaining
#           regulatory benchmarks and specific normative guidelines.
#         - *How* - It processes requests to list, create, update, or remove
#           normative articles, supporting both HTML and JSON responses.
#         - *Why* - It ensures that the application has a centralized and
#           verifiable repository of regulatory rules used for compliance
#           and benchmark tracking.
#
# Attributes:: - *@normative_articles* [Collection] - A list of available articles.
#              - *@normative_article* [Object] - A single specific article being processed.
#
class NormativeArticlesController < ApplicationController

  # =============================================================
  #                        CONFIGURATION
  # =============================================================

  # Ensures only authenticated users can access the controller's functionality.
  before_action :authenticate_user!

  # Loads the specified normative article before performing sensitive operations.
  before_action :load_normative_article, only: %i[show edit update destroy]

  # Enforces authorization checks to restrict data access and management privileges.
  before_action :authorize_normative_article, only: %i[show update destroy]

  # =============================================================
  #                       PUBLIC METHODS
  # =============================================================

  # == index
  #
  # @author Moisés Reis
  #
  # Retrieves and displays a paginated, filterable list of all normative articles.
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

  # == show
  #
  # @author Moisés Reis
  #
  # Displays details for a specific normative article, including JSON serialization.
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

  # == new
  #
  # @author Moisés Reis
  #
  # Initializes a new normative article object for the creation form.
  def new
    @normative_article = NormativeArticle.new

    authorize! :create, NormativeArticle
  rescue CanCan::AccessDenied => e
    redirect_to normative_articles_path, alert: e.message
  end

  # == edit
  #
  # @author Moisés Reis
  #
  # Placeholder for loading the editing interface.
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  #
  # Validates and saves a new normative article to the database.
  def create
    @normative_article = NormativeArticle.new(normative_article_params)

    authorize! :create, NormativeArticle

    if @normative_article.save
      respond_to do |format|
        format.html {
          redirect_to normative_article_path(@normative_article),
                      notice: 'Artigo normativo criado com sucesso.'
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

  # == update
  #
  # @author Moisés Reis
  #
  # Applies changes to an existing normative article and returns a status response.
  def update
    if @normative_article.update(normative_article_params)
      respond_to do |format|
        format.html {
          redirect_to normative_article_path(@normative_article),
                      notice: 'Artigo normativo atualizado com sucesso.'
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

  # == destroy
  #
  # @author Moisés Reis
  #
  # Removes a normative article from the database, handling common error cases.
  def destroy
    @normative_article.destroy!

    respond_to do |format|
      format.html {
        redirect_to normative_articles_path,
                    notice: 'Artigo normativo deletado com sucesso.',
                    status: :see_other
      }
      format.json {
        render json: {
          status: 'Success',
          message: 'Artigo normativo deletado com sucesso.'
        }, status: :ok
      }
    end

  rescue ActiveRecord::RecordNotDestroyed => e
    respond_to do |format|
      format.html {
        redirect_to normative_article_path(@normative_article),
                    alert: 'Houve um problema ao deletar o artigo normativo'
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

  # =============================================================
  #                       HELPER UTILITIES
  # =============================================================

  private

  # Retrieves the normative article record from the database.
  def load_normative_article
    @normative_article = NormativeArticle.find(params[:id])
  end

  # Authorizes the current user to perform actions on the article.
  def authorize_normative_article
    authorize! :read, @normative_article if action_name == 'show'
    authorize! :manage, @normative_article if %w[update destroy].include?(action_name)
  end

  # Sanitizes input parameters allowed for article creation or updates.
  def normative_article_params
    params.require(:normative_article).permit(
      :article_name,
      :article_number,
      :article_body,
      :description,
      :benchmark_target,
      :minimum_target,
      :maximum_target,
      :category
    )
  end
end