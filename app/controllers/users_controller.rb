# Handles user management workflows and administrative user operations.
#
# This controller coordinates user listing, detail presentation,
# creation, updates, and deletion through dedicated query and service
# objects while maintaining thin-controller architecture principles.
#
# @author Moisés Reis

class UsersController < ApplicationController

  # ==========================================================================
  # FILTERS
  # ==========================================================================

  # Ensures only authenticated users can access controller actions.
  before_action :authenticate_user!

  # Loads the target user entity for member actions.
  #
  # Actions:
  # - show
  # - edit
  # - update
  # - destroy
  before_action :set_user, only: %i[show edit update destroy]

  # ==========================================================================
  # INDEX & DETAIL ACTIONS
  # ==========================================================================

  # Displays the paginated user listing.
  #
  # This action delegates filtering, searching, eager loading,
  # and pagination behavior to {Users::IndexQuery}.
  #
  # @return [void]
  def index
    result = Users::IndexQuery.call(
      params[:q],
      page:  params[:page],
      actor: current_user
    )

    @q     = result.search
    @users = result.records
  end

  # Displays detailed user information and aggregated dashboard metrics.
  #
  # This action delegates dashboard and portfolio aggregation behavior
  # to {Users::ShowService}.
  #
  # @return [void]
  def show
    @data = Users::ShowService.call(@user)
  end

  # ==========================================================================
  # CREATION ACTIONS
  # ==========================================================================

  # Displays the user creation form.
  #
  # @return [void]
  def new
    @form = UserForm.new
  end

  # Creates a new user record through the creation service workflow.
  #
  # On success:
  # - redirects to the created user
  #
  # On failure:
  # - re-renders the form
  # - exposes validation errors
  #
  # @return [void]
  def create
    result = Users::CreationService.call(
      user_params,
      actor: current_user
    )

    if result.success?
      redirect_to(
        result.user,
        notice: t("users.create.success")
      )
    else
      @form = result.form

      flash.now[:alert] = t("users.create.failure")

      render(:new, status: :unprocessable_entity)
    end
  end

  # ==========================================================================
  # UPDATE ACTIONS
  # ==========================================================================

  # Displays the user edit form.
  #
  # @return [void]
  def edit
    @form = UserForm.from_user(@user)
  end

  # Updates an existing user through the update service workflow.
  #
  # On success:
  # - redirects to the updated user
  #
  # On failure:
  # - re-renders the form
  # - exposes validation errors
  #
  # @return [void]
  def update
    result = Users::UpdateService.call(
      @user,
      user_params,
      actor: current_user
    )

    if result.success?
      redirect_to(
        @user,
        notice: t("users.update.success")
      )
    else
      @form = result.form

      flash.now[:alert] = t("users.update.failure")

      render(:edit, status: :unprocessable_entity)
    end
  end

  # ==========================================================================
  # DELETION ACTIONS
  # ==========================================================================

  # Deletes an existing user through the deletion service workflow.
  #
  # On success:
  # - redirects to the user listing
  #
  # On failure:
  # - redirects to the user listing
  # - exposes an error flash message
  #
  # @return [void]
  def destroy
    result = Users::DeletionService.call(
      @user,
      actor: current_user
    )

    if result.success?
      redirect_to(
        users_url,
        notice: t("users.destroyed"),
        status: :see_other
      )
    else
      redirect_to(
        users_url,
        alert: t("users.destroy_failed"),
        status: :see_other
      )
    end
  end

  private

  # ==========================================================================
  # PRIVATE METHODS
  # ==========================================================================

  # Loads the target user entity from the request parameters.
  #
  # @return [void]
  # @raise [ActiveRecord::RecordNotFound] If the user does not exist.
  def set_user
    @user = User.find(params[:id])
  end

  # Returns the permitted user parameters.
  #
  # @return [ActionController::Parameters] Strong parameter whitelist.
  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email,
      :role,
      :password,
      :password_confirmation
    )
  end
end
