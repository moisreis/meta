# === normative_articles_controller
#
# @author Moisés Reis
# @added 12/04/2025
# @package *Meta*
# @description This controller manages all available **NormativeArticle** records in the system.
#              It handles listing, viewing, creation, editing, and deletion of regulatory
#              guidelines that investment funds follow, primarily for administrative users.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls the master list of all normative articles
#           (regulatory rules and guidelines) that define investment fund behavior.
#         - *[How]* It uses authorization checks via **CanCan** to manage who can create
#           or modify articles, and it handles searching, filtering, and sorting of the article list.
#         - *[Why]* It provides a centralized and secure mechanism for managing the regulatory
#           framework and compliance guidelines used throughout the application.
#
# Attributes:: - *@normative_article* @object - The specific article being handled (show, update, destroy).
#              - *@normative_articles* @collection - The filtered and paginated list of articles for the index view.
#
class NormativeArticlesController < ApplicationController

  # Explanation:: This command confirms that a user is successfully logged into
  #               the system before allowing access to any actions within this controller.
  before_action :authenticate_user!

  # Explanation:: This runs before viewing, editing, updating, or destroying a record. It finds
  #               the specific **NormativeArticle** from the database using the ID provided
  #               in the web address.
  before_action :load_normative_article, only: [
    :show,
    :edit,
    :update,
    :destroy
  ]

  # Explanation:: This runs immediately after loading the record. It checks the user's
  #               permissions via **CanCan** to ensure they are authorized to perform
  #               the requested action (read, update, or destroy) on this specific article.
  before_action :authorize_normative_article, only: [
    :show,
    :update,
    :destroy
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves and displays a list of all normative articles.
  #        It applies search, filtering, and sorting before displaying the results to the user.
  #
  # Attributes:: - *@q* @Ransack::Search - holds the search object for the collection.
  #             - *@normative_articles* @ActiveRecord::Relation - contains the final paginated list.
  #
  def index

    # Explanation:: This defines the initial set of articles by getting all **NormativeArticle**
    #               records and ordering them by creation date, with the newest appearing first.
    base_scope = NormativeArticle.all.order(created_at: :desc)

    # Explanation:: This initializes the search object using the **Ransack** gem,
    #               applying any search criteria passed by the user in the web address.
    @q = base_scope.ransack(params[:q])

    # Explanation:: This executes the search query defined by **Ransack**, returning a
    #               unique list of normative articles that match the search criteria.
    filtered = @q.result(distinct: true)

    # Explanation:: This checks the web address for a specific column to sort by, defaulting
    #               to sorting by the `created_at` timestamp if no sort column is specified.
    sort = params[:sort].presence || "created_at"

    # Explanation:: This checks the web address for a specific sort direction, defaulting
    #               to descending order (newest first) if none is specified.
    direction = params[:direction].presence || "desc"

    # Explanation:: This applies the determined sort column and direction to the
    #               filtered list of normative articles.
    sorted = filtered.order("#{sort} #{direction}")

    # Explanation:: This prepares the final data for the page, dividing the complete
    #               list into pages of 20 items to improve performance and readability.
    @normative_articles = sorted.page(params[:page]).per(20)

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
  # @category *Read*
  #
  # Read:: This action prepares the specific article record that was loaded earlier.
  #        It makes the data available for the view to display all its details to the user.
  #
  # Attributes:: - *@normative_article* @NormativeArticle - The single article object found by the `load_normative_article` filter.
  #
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
  # @category *Read*
  #
  # Read:: This action creates a new, blank **NormativeArticle** object.
  #        This empty object is used by the form to gather input from the user for creation.
  #
  # Attributes:: - *@normative_article* @NormativeArticle - A new, unsaved article instance.
  #
  def new
    @normative_article = NormativeArticle.new

    # Explanation:: This checks if the current user has permission to create normative articles.
    #               If not, they are redirected to the index page with an error message.
    authorize! :create, NormativeArticle
  rescue CanCan::AccessDenied => e
    redirect_to normative_articles_path, alert: e.message
  end

  # == edit
  #
  # @author Moisés Reis
  # @category *Edit*
  #
  # Edit:: This action prepares the view to display the existing article's
  #        data, allowing the user to make changes to the record.
  #
  # Attributes:: - *@normative_article* @NormativeArticle - The existing article object loaded by the `before_action` filter.
  #
  def edit
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Create*
  #
  # Create:: This action attempts to save a new normative article record to the
  #          database. It first checks for creation permissions and handles
  #          both successful saves and validation errors.
  #
  # Attributes:: - *@normative_article* @NormativeArticle - The new article record.
  #
  def create
    @normative_article = NormativeArticle.new(normative_article_params)

    # Explanation:: This uses **CanCan** to verify that the current user has permission
    #               to create a new **NormativeArticle** record in the system.
    authorize! :create, NormativeArticle

    # Explanation:: This attempts to save the new article to the database.
    #               If successful, it redirects to the show page with a success message.
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

  # == update
  #
  # @author Moisés Reis
  # @category *Update*
  #
  # Update:: This action attempts to modify an existing normative article record
  #          with new data. It handles both successful updates and validation errors.
  #
  # Attributes:: - *@normative_article* @NormativeArticle - The article to be updated.
  #
  def update

    # Explanation:: This attempts to update the article with the sanitized parameters.
    #               If successful, it redirects to the show page with a success message.
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

  # == destroy
  #
  # @author Moisés Reis
  # @category *Delete*
  #
  # Delete:: This action deletes the normative article record from the database.
  #          It handles successful deletion and any errors that might occur.
  #
  # Attributes:: - *@normative_article* @NormativeArticle - The article object to be destroyed.
  #
  def destroy

    # Explanation:: This attempts to destroy the article record.
    #               If successful, it redirects to the index with a success message.
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

  # == load_normative_article
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds a single article record in the
  #           database using the ID from the web request. It stores the record for
  #           use by other controller methods.
  #
  # Attributes:: - *params[:id]* @integer - The identifier of the article record being requested.
  #
  def load_normative_article
    @normative_article = NormativeArticle.find(params[:id])
  end

  # == authorize_normative_article
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method checks the current action being performed
  #            and verifies the user's permissions (**read** or **manage**)
  #            on the loaded normative article record.
  #
  # Attributes:: - *action_name* @string - The name of the current controller action (e.g., 'show').
  #
  def authorize_normative_article

    # Explanation:: This specifically authorizes the user to read the article record
    #               if the current action is 'show'.
    authorize! :read, @normative_article if action_name == 'show'

    # Explanation:: This specifically authorizes the user to manage (update or destroy)
    #               the article record if the current action is 'update' or 'destroy'.
    authorize! :manage, @normative_article if %w[update destroy].include?(action_name)
  end

  # == normative_article_params
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method sanitizes all incoming data from the
  #            normative article form. It ensures that only specifically permitted
  #            fields are allowed to be saved to the database.
  #
  # Attributes:: - *params* @Hash - The raw data hash received from the user form submission.
  #
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