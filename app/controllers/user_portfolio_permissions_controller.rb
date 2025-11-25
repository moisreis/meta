# === user_portfolio_permissions_controller
#
# @author Moisés Reis
# @added 11/24/2025
# @package *Meta*
# @description This controller manages the sharing of a specific **Portfolio** with other users,
#              handling creation, retrieval, modification, and removal of access rights via the
#              **UserPortfolioPermission** model. The explanations are in the present simple tense.
# @category *Controller*
#
# Usage:: - *[What]* This code block controls which users have access to a specific portfolio and their level of permission.
#         - *[How]* It uses API endpoints to create, read, update, and delete permission records linked to a **Portfolio** and a **User**.
#         - *[Why]* It ensures secure collaboration by allowing portfolio owners to share their financial data with others while controlling the level of access.
#
# Attributes:: - *@portfolio* @object - The parent portfolio that is being shared.
#              - *@permission* @object - The specific permission record being managed.
#
class UserPortfolioPermissionsController < ApplicationController

  # Explanation:: This command confirms that a user is successfully logged into
  #               the system before allowing access to any actions within this controller.
  before_action :authenticate_user!

  # Explanation:: This runs before most actions. It finds the parent **Portfolio** record
  #               from the database using the `portfolio_id` provided in the web address.
  before_action :load_portfolio

  # Explanation:: This runs before actions that modify data (create, update, destroy).
  #               It calls `authorize_portfolio_management` to verify the user is either the
  #               portfolio owner or an administrator.
  before_action :authorize_portfolio_management, except: [
    :index,
    :show
  ]

  # Explanation:: This runs before actions that only read data (index, show).
  #               It calls `authorize_portfolio_read` to ensure the user has at least
  #               read permission on the portfolio before proceeding.
  before_action :authorize_portfolio_read, only: [
    :index,
    :show
  ]

  # Explanation:: This runs before showing, updating, or destroying a specific permission.
  #               It calls `load_permission` to find the exact permission record
  #               using the ID provided in the web address.
  before_action :load_permission, only: [
    :show,
    :update,
    :destroy
  ]

  # == index
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves and displays a list of all sharing permissions for the loaded portfolio.
  #        It is typically used by the portfolio owner to see who has access and their permission level.
  #
  # Attributes:: - *@permissions* - The collection of **UserPortfolioPermission** records for the portfolio.
  #
  def index
    @permissions = @portfolio.user_portfolio_permissions.includes(:user)

    # Explanation:: This formats the list of permission records into a structured JSON
    #               response, including the ID, email, and full name of each shared user
    #               along with the access level and description.
    render json: {
      status: 'Success',
      data: @permissions.map do |permission|
        {
          id: permission.id,
          user: {
            id: permission.user.id,
            email: permission.user.email,
            full_name: permission.user.full_name
          },
          permission_level: permission.permission_level,
          permission_description: permission.permission_description,
          created_at: permission.created_at
        }
      end
    }
  end

  # == show
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action retrieves and displays the detailed information for a single permission record.
  #        It provides metadata about the permission, the user, and the portfolio being shared.
  #
  # Attributes:: - *@permission* - The single **UserPortfolioPermission** record found by the `load_permission` filter.
  #
  def show
    render json: {
      status: 'Success',
      data: {
        id: @permission.id,
        user: {
          id: @permission.user.id,
          email: @permission.user.email,
          full_name: @permission.user.full_name
        },
        portfolio: {
          id: @permission.portfolio.id,
          name: @permission.portfolio.name
        },
        permission_level: @permission.permission_level,
        permission_description: @permission.permission_description,
        created_at: @permission.created_at,
        updated_at: @permission.updated_at
      }
    }
  end

  # == create
  #
  # @author Moisés Reis
  # @category *Create*
  #
  # Create:: This action attempts to create a new permission record, granting another user access to the portfolio.
  #          It verifies the creation and returns the new permission details or any validation errors.
  #
  # Attributes:: - *permission_params* - The sanitized input data containing the user ID and desired permission level.
  #
  def create
    @permission = @portfolio.user_portfolio_permissions.build(permission_params)

    # Explanation:: This checks if the new permission object successfully passes
    #               all database validations and saves the record, thereby granting access.
    if @permission.save
      render json: {
        status: 'Success',
        message: 'Portfolio shared successfully',
        data: {
          id: @permission.id,
          user: {
            id: @permission.user.id,
            email: @permission.user.email,
            full_name: @permission.user.full_name
          },
          permission_level: @permission.permission_level,
          permission_description: @permission.permission_description
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        errors: @permission.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # == update
  #
  # @author Moisés Reis
  # @category *Update*
  #
  # Update:: This action attempts to modify the permission level of an existing sharing record.
  #          It allows the portfolio owner to change the access rights (e.g., from read-only to management).
  #
  # Attributes:: - *permission_params* - The sanitized input data for updating the permission level.
  #
  def update

    # Explanation:: This attempts to update the permission object with new data,
    #               ensuring that the `user_id` cannot be changed after the permission record is created.
    if @permission.update(permission_params.except(:user_id))
      render json: {
        status: 'Success',
        message: 'Permission updated successfully',
        data: {
          id: @permission.id,
          permission_level: @permission.permission_level,
          permission_description: @permission.permission_description,
          updated_at: @permission.updated_at
        }
      }
    else
      render json: {
        status: 'error',
        errors: @permission.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # == destroy
  #
  # @author Moisisés Reis
  # @category *Delete*
  #
  # Delete:: This action deletes a specific permission record, immediately revoking access to the portfolio for the shared user.
  #          It confirms the removal with the email of the user whose access was removed.
  #
  # Attributes:: - *@permission* - The permission record to be destroyed.
  #
  def destroy

    # Explanation:: This stores the email address of the user whose access is being
    #               revoked, so the email can be used in the confirmation message after deletion.
    user_email = @permission.user.email

    # Explanation:: This permanently removes the permission record from the database,
    #               which immediately revokes the user's access to the portfolio.
    @permission.destroy

    # Explanation:: This sends a confirmation message to the client, stating that
    #               portfolio access was successfully removed for the specified user.
    render json: {
      status: 'Success',
      message: "Portfolio access removed for #{user_email}"
    }
  end

  # == available_users
  #
  # @author Moisés Reis
  # @category *Read*
  #
  # Read:: This action provides a list of all users who are currently eligible to be granted access to the portfolio.
  #        It excludes the portfolio owner and any users who already have sharing permissions.
  #
  # Attributes:: - *available_users* - A collection of **User** records who do not yet have access.
  #
  def available_users

    # Explanation:: This gathers the ID of the portfolio owner and the IDs of all users
    #               who already have sharing permissions, so they can be excluded from the list.
    excluded_user_ids = [@portfolio.user_id] + @portfolio.user_portfolio_permissions.pluck(:user_id)

    # Explanation:: This queries the **User** model to find users whose IDs are not in the
    #               excluded list, selecting only necessary fields and sorting them by email for display.
    available_users = User.where.not(id: excluded_user_ids)
                          .select(
                            :id,
                            :email,
                            :first_name,
                            :last_name
                          )
                          .order(:email)

    # Explanation:: This formats and sends the list of eligible users with their ID,
    #               email, and full name to the client in a successful JSON response.
    render json: {
      status: 'Success',
      data: available_users.map do |user|
        {
          id: user.id,
          email: user.email,
          full_name: user.full_name
        }
      end
    }
  end

  private

  # == load_portfolio
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds the parent **Portfolio** record in the
  #           database using the `portfolio_id` from the web request parameters.
  #
  # Attributes:: - *params[:portfolio_id]* - The identifier of the portfolio record.
  #
  def load_portfolio
    @portfolio = Portfolio.find(params[:portfolio_id])
  end

  # == load_permission
  #
  # @author Moisés Reis
  # @category *Utility*
  #
  # Utility:: This private method finds a single **UserPortfolioPermission** record
  #           scoped to the loaded portfolio using the ID from the web request.
  #
  # Attributes:: - *params[:id]* - The identifier of the specific permission record.
  #
  def load_permission
    @permission = @portfolio.user_portfolio_permissions.find(params[:id])
  end

  # == authorize_portfolio_management
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method checks if the current user has the authority to
  #            manage permissions. Only the portfolio owner or an application administrator
  #            is allowed to proceed.
  #
  # Attributes:: - *current_user* - The authenticated user trying to perform the action.
  #
  def authorize_portfolio_management

    # Explanation:: This condition ensures that only the portfolio owner (matching `user_id`)
    #               or an administrator (`admin?`) can proceed with managing the sharing permissions.
    unless current_user.admin? || @portfolio.user_id == current_user.id
      render json: {
        status: 'error',
        message: 'You are not authorized to manage this portfolio'
      }, status: :forbidden
    end
  end

  # == authorize_portfolio_read
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method verifies the user's permission to view the portfolio.
  #            It uses the **CanCan** authorization system to ensure the user has at least read access.
  #
  # Attributes:: - *@portfolio* - The portfolio record being checked for read access.
  #
  def authorize_portfolio_read
    authorize! :read, @portfolio
  end

  # == permission_params
  #
  # @author Moisés Reis
  # @category *Security*
  #
  # Security:: This private method sanitizes all incoming data for permission creation or update.
  #            It ensures that only the `user_id` and the `permission_level` fields are permitted.
  #
  # Attributes:: - *params* - The raw data hash received from the user request.
  #
  def permission_params
    params.require(:user_portfolio_permission).permit(:user_id, :permission_level)
  end
end