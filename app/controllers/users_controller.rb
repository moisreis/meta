# app/controllers/users_controller.rb
#
# Controls user management workflows, including listing, creation,
# visualization, updates, and deletion of user accounts.
#
# This controller coordinates form objects, query layers, and service
# objects responsible for encapsulating business rules related to users.
#
# @author Moisés Reis
class UsersController < ApplicationController

  # =============================================================
  #                           1. FILTERS
  # =============================================================

  before_action :authenticate_user!
  before_action :set_user, only: %i[show edit update destroy]

  # =============================================================
  #                        2a. INDEX
  # =============================================================

  # Displays the paginated user listing page.
  #
  # Delegates searching, filtering, authorization scoping,
  # and pagination responsibilities to {Users::IndexQuery}.
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

  # =============================================================
  #                         2b. SHOW
  # =============================================================

  # Displays the detailed profile page for a specific user.
  #
  # Delegates data aggregation responsibilities to
  # {Users::ShowService}, centralizing presentation-related
  # queries and metrics outside the controller layer.
  #
  # @return [void]
  def show
    @data = Users::ShowService.call(@user)
  end

  # =============================================================
  #                          2c. NEW
  # =============================================================

  # Initializes the form object used to render the user creation form.
  #
  # @return [void]
  def new
    @form = UserForm.new
  end

  # =============================================================
  #                        2d. CREATE
  # =============================================================

  # Creates a new user account using the submitted form data.
  #
  # Delegates validation and persistence responsibilities to
  # {Users::CreationService}.
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

  # =============================================================
  #                          2e. EDIT
  # =============================================================

  # Initializes the form object used to edit an existing user.
  #
  # @return [void]
  def edit
    @form = UserForm.from_user(@user)
  end

  # =============================================================
  #                         2f. UPDATE
  # =============================================================

  # Updates an existing user account using the submitted form data.
  #
  # Delegates update rules and persistence responsibilities to
  # {Users::UpdateService}.
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

  # =============================================================
  #                        2g. DESTROY
  # =============================================================

  # Permanently deletes the selected user account.
  #
  # Delegates authorization and deletion responsibilities to
  # {Users::DeletionService}.
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

  # =============================================================
  #                     3a. USER LOOKUP
  # =============================================================

  # Finds the user associated with the provided route identifier.
  #
  # @return [void]
  # @raise [ActiveRecord::RecordNotFound] If the user does not exist.
  def set_user
    @user = User.find(params[:id])
  end

  # =============================================================
  #                   3b. STRONG PARAMETERS
  # =============================================================

  # Defines the permitted parameters accepted for user creation
  # and update operations.
  #
  # @return [ActionController::Parameters] Sanitized user parameters.
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