# === users_controller
#
# @author Moisés Reis
# @added 11/20/2025
# @package *Meta*
# @description Defines the controller that manages operations related to **User** records.
#              Ensures that all actions run through **ApplicationController** so that
#              authentication, security, and shared behavior apply consistently.
# @category *Controller*
#
# Usage:: - *[what]* This controller handles CRUD actions for **User** entities.
#         - *[how]* It authenticates access, retrieves user records, applies search
#                   through **Ransack**, and persists changes using strong parameters.
#         - *[why]* It organizes all user-management flows in a single structure,
#                   ensuring clarity, maintainability, and predictable behavior
#                   across the administrative interface.
#
# Attributes:: - *@users* @collection - stores the paginated collection of users
#              - *@user* @object - stores a single user for show, edit, and update actions
#              - *@q* @object - holds the Ransack search object
#
class UsersController < ApplicationController
  before_action :authenticate_user!

  # [Action] Lists users with filtering and pagination.
  #          Uses Ransack to process search queries.
  def index
    @q = User.ransack(params[:q])
    @users = @q.result(distinct: true).page(params[:page]).per(20)
  end

  # [Action] Shows a specific user by ID.
  def show
    @user = User.find(params[:id])
  end

  # [Action] Initializes a new user instance for the form.
  def new
    @user = User.new
  end

  # [Action] Creates a user and handles success or validation errors.
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # [Action] Loads a user for editing.
  def edit
    @user = User.find(params[:id])
  end

  # [Action] Updates a user and responds with redirect or validation errors.
  def update
    @user = User.find(params[:id])

    if @user.update(user_params)
      redirect_to @user, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # [Helper] Whitelists allowed parameters for secure updates.
  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :role)
  end
end
