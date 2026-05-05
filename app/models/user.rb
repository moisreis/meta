# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           not null
#  encrypted_password     :string           not null
#  first_name             :string           not null
#  last_name              :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :string           default("user"), not null
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Represents an authenticated application user responsible for
# accessing investment portfolios and protected financial features.
#
# This model integrates authentication through Devise, enforces
# authorization boundaries through roles, and manages ownership
# and shared access relationships for portfolios.
#
# @author Moisés Reis
class User < ApplicationRecord

  # =============================================================
  #                      1. AUTHENTICATION
  # =============================================================

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  # =============================================================
  #                       2. ASSOCIATIONS
  # =============================================================

  has_many :portfolios, dependent: :destroy

  has_many :user_portfolio_permissions,
           dependent: :destroy

  has_many :accessible_portfolios,
           through: :user_portfolio_permissions,
           source: :portfolio

  # =============================================================
  #                        3. VALIDATIONS
  # =============================================================

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false }

  validates :first_name,
            presence: true,
            length: {
              minimum: 2,
              maximum: 50
            }

  validates :last_name,
            presence: true,
            length: {
              minimum: 2,
              maximum: 50
            }

  # =============================================================
  #                           4. ENUMS
  # =============================================================

  enum :role,
       {
         user:  "user",
         admin: "admin"
       }

  # =============================================================
  #                 5a. DISPLAY HELPERS
  # =============================================================

  # Returns the user's full display name.
  #
  # @return [String] Concatenated first and last name.
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # =============================================================
  #               6a. RANSACK CONFIGURATION
  # =============================================================

  # Defines the attributes available for Ransack filtering
  # and searching operations.
  #
  # @param auth_object [Object, nil] Optional authorization object.
  # @return [Array<String>] Allowed searchable attributes.
  def self.ransackable_attributes(auth_object = nil)
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

  # Defines the associations available for Ransack join queries.
  #
  # @param auth_object [Object, nil] Optional authorization object.
  # @return [Array<String>] Allowed searchable associations.
  def self.ransackable_associations(auth_object = nil)
    [
      "accessible_portfolios",
      "portfolios",
      "user_portfolio_permissions"
    ]
  end
end