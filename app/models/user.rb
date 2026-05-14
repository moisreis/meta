# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           not null
#  encrypted_password     :string           not null
#  first_name             :string           not null
#  last_name              :string           not null
#  role                   :string           not null
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Handles authentication, authorization, and portfolio ownership behavior
# for application users.
#
# This model integrates Devise authentication modules, role-based access
# control, portfolio ownership relationships, and Ransack search exposure.
#
# @author Moisés Reis

class User < ApplicationRecord

  # ==========================================================================
  # AUTHENTICATION
  # ==========================================================================

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  # ==========================================================================
  # ASSOCIATIONS
  # ==========================================================================

  # Portfolios directly owned by the user.
  #
  # @return [ActiveRecord::Associations::CollectionProxy<Portfolio>]
  has_many :portfolios, dependent: :destroy

  # Portfolio permission relationships assigned to the user.
  #
  # @return [ActiveRecord::Associations::CollectionProxy<UserPortfolioPermission>]
  has_many :user_portfolio_permissions, dependent: :destroy

  # Portfolios accessible to the user through delegated permissions.
  #
  # @return [ActiveRecord::Associations::CollectionProxy<Portfolio>]
  has_many :accessible_portfolios,
           through: :user_portfolio_permissions,
           source: :portfolio

  # ==========================================================================
  # VALIDATIONS
  # ==========================================================================

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false }

  validates :first_name,
            presence: true,
            length: { minimum: 2, maximum: 50 }

  validates :last_name,
            presence: true,
            length: { minimum: 2, maximum: 50 }

  # ==========================================================================
  # ENUMERATIONS
  # ==========================================================================

  # Defines role-based authorization levels for users.
  #
  # @return [Hash<Symbol, String>] Available user role mappings.
  enum :role, { user: "user", admin: "admin" }

  # ==========================================================================
  # PUBLIC METHODS
  # ==========================================================================

  # Returns the user's full display name.
  #
  # @return [String] Concatenated first and last name.
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # ==========================================================================
  # RANSACK CONFIGURATION
  # ==========================================================================

  class << self

    # Returns the list of searchable attributes exposed to Ransack.
    #
    # @param auth_object [Object, nil] Optional authorization context.
    # @return [Array<String>] Allowed searchable attribute names.
    def ransackable_attributes(auth_object = nil)
      [
        "created_at",
        "current_sign_in_at",
        "current_sign_in_ip",
        "email",
        "encrypted_password",
        "first_name",
        "id",
        "id_value",
        "last_name",
        "last_sign_in_at",
        "last_sign_in_ip",
        "remember_created_at",
        "reset_password_sent_at",
        "reset_password_token",
        "role",
        "sign_in_count",
        "updated_at"
      ]
    end

    # Returns the list of searchable associations exposed to Ransack.
    #
    # @param auth_object [Object, nil] Optional authorization context.
    # @return [Array<String>] Allowed searchable association names.
    def ransackable_associations(auth_object = nil)
      [
        "accessible_portfolios",
        "portfolios",
        "user_portfolio_permissions"
      ]
    end
  end
end
