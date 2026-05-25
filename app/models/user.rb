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
# Represents an application user with authentication, role-based
# authorization, and portfolio ownership capabilities.
#
# A User authenticates via Devise, owns portfolios, receives
# delegated access through portfolio permissions, and defines
# role-based access levels for the application.
#
# This model does NOT implement business rules for portfolio
# calculations or financial metrics. Those concerns belong to
# dedicated calculators and service objects.
#
# @author Moisés Reis

class User < ApplicationRecord

  # =============================================================
  #                        AUTHENTICATION
  # =============================================================

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :trackable

  has_one_attached :avatar

  # =============================================================
  #                         ASSOCIATIONS
  # =============================================================

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

  # =============================================================
  #                           VALIDATIONS
  # =============================================================

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false }

  validates :first_name,
            presence: true,
            length: { minimum: 2, maximum: 50 }

  validates :last_name,
            presence: true,
            length: { minimum: 2, maximum: 50 }

  # =============================================================
  #                         ENUMERATIONS
  # =============================================================

  # Defines role-based authorization levels for users.
  #
  # @return [Hash<Symbol, String>] Available user role mappings.
  enum :role, { user: "user", admin: "admin" }

  # =============================================================
  #                         PUBLIC METHODS
  # =============================================================

  # Returns the user's full display name.
  #
  # @return [String] Concatenated first and last name.
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # =============================================================
  #                        RANSACK SUPPORT
  # =============================================================

  # --- SEARCHABLE ATTRIBUTES -----------------------------------

  # Defines the attributes allowed for Ransack filtering.
  #
  # @param auth_object [Object, nil]
  #   Authorization context provided by Ransack.
  #
  # @return [Array<String>]
  #   List of searchable attributes.
  def self.ransackable_attributes(auth_object = nil)
    %w[
      created_at
      email
      first_name
      id
      last_name
      role
      sign_in_count
      updated_at
    ]
  end

  # --- SEARCHABLE ASSOCIATIONS ---------------------------------

  # Defines the associations allowed for Ransack joins.
  #
  # @param auth_object [Object, nil]
  #   Authorization context provided by Ransack.
  #
  # @return [Array<String>]
  #   List of searchable associations.
  def self.ransackable_associations(auth_object = nil)
    %w[
      accessible_portfolios
      portfolios
      user_portfolio_permissions
    ]
  end
end
