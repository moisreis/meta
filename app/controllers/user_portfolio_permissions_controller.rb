# === user_portfolio_permissions_controller
#
# @author Moisés Reis
# @added 11/21/2025
# @package *Meta*
# @description Manages user access to **Portfolios**, providing actions that create,
#              update, display and remove sharing rules in a clear and API-friendly shape.
#              It integrates with **Portfolio**, **User**, and **UserPortfolioPermission**
#              to maintain a consistent sharing model.
# @category *Controller*
#
# Usage:: - *[what]* Exposes API endpoints that list, show, create, update and delete
#                    sharing permissions for a given **Portfolio**
#         - *[how]* Processes JSON requests, load the relevant portfolio, authorize access,
#                   and interact with **UserPortfolioPermission** records to maintain
#                   the correct permission state
#         - *[why]* Ensures the app handles portfolio sharing in a centralized, controlled,
#                   and secure way, allowing collaboration features to function reliably
#
# Attributes:: - *@portfolio* @instance - stores the loaded **Portfolio** for permission operations
#              - *@permission* @instance - stores the loaded **UserPortfolioPermission** used in show,
#                                          update and destroy actions
#
class UserPortfolioPermissionsController < ApplicationController

  before_action :authenticate_user!
  before_action :load_portfolio
  before_action :authorize_portfolio_management, except: [:index, :show]
  before_action :authorize_portfolio_read, only: [:index, :show]
  before_action :load_permission, only: [:show, :update, :destroy]

  # [Action] This action fetches all permission records for the current portfolio.
  #          It displays who has access to the portfolio and their respective permission levels.
  #          It responds with a JSON array of these permission objects, including the user's
  #          details and the permission description.
  def index
    @permissions = @portfolio.user_portfolio_permissions.includes(:user)

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

  # [Action] This action retrieves and displays the details of a single permission record.
  #          It shows the specific user, the portfolio they have access to, and the level
  #          of permission granted, providing a detailed JSON response.
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

  # [Action] This action attempts to grant a new permission level to a user for the current portfolio.
  #          It builds the new permission record using the submitted parameters. If successful,
  #          it saves the record and returns a success message and the new permission details.
  #          If it fails validation, it returns an error with the reasons.
  def create
    @permission = @portfolio.user_portfolio_permissions.build(permission_params)

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

  # [Action] This action modifies the permission level for an existing authorized user.
  #          It takes the new permission parameters (excluding the user ID, which cannot be changed).
  #          If the update succeeds, it returns a success message and the updated permission details.
  #          Otherwise, it sends back validation errors.
  def update
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

  # [Action] This action revokes access to the portfolio for a specific user.
  #          It finds the permission record and deletes it. It returns a success message
  #          confirming that access has been removed for the specified user's email.
  def destroy
    user_email = @permission.user.email
    @permission.destroy

    render json: {
      status: 'Success',
      message: "Portfolio access removed for #{user_email}"
    }
  end

  # [Action] This action finds and lists all users who do not yet have access to the current portfolio.
  #          It excludes the portfolio owner and users who already have permission.
  #          It provides this list in a JSON format so the owner can easily share the portfolio
  #          with new people.
  def available_users
    excluded_user_ids = [@portfolio.user_id] + @portfolio.user_portfolio_permissions.pluck(:user_id)
    available_users = User.where.not(id: excluded_user_ids)
                          .select(:id, :email, :first_name, :last_name)
                          .order(:email)

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

  # [Helper] This private method finds the **Portfolio** record using the `portfolio_id` parameter
  #          from the request. It stores the found portfolio in the `@portfolio` instance variable
  #          so that other actions can use it.
  def load_portfolio
    @portfolio = Portfolio.find(params[:portfolio_id])
  end

  # [Helper] This private method finds a specific **UserPortfolioPermission** record within the
  #          current portfolio using the `id` parameter. It stores the permission object in the
  #          `@permission` instance variable for use in `show`, `update`, and `destroy` actions.
  def load_permission
    @permission = @portfolio.user_portfolio_permissions.find(params[:id])
  end

  # [Helper] This method checks if the current user has the authority to change permissions.
  #          It allows access only if the user is an admin or is the original owner of the portfolio.
  #          If authorization fails, it immediately renders a 403 Forbidden error.
  def authorize_portfolio_management
    unless current_user.admin? || @portfolio.user_id == current_user.id
      render json: {
        status: 'error',
        message: 'You are not authorized to manage this portfolio'
      }, status: :forbidden
    end
  end

  # [Helper] This method uses the **CanCanCan** library (`authorize!`) to verify that the current
  #          user has permission to read the `@portfolio` object. This ensures only authorized
  #          users can view the list or details of permissions.
  def authorize_portfolio_read
    authorize! :read, @portfolio
  end

  # [Helper] This private method secures the parameters submitted for creating or updating a permission.
  #          It uses Rails' strong parameters feature to permit only `user_id` and `permission_level`.
  def permission_params
    params.require(:user_portfolio_permission).permit(:user_id, :permission_level)
  end
end