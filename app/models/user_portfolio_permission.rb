# === user_portfolio_permission.rb
#
# @author Moisés Reis
# @added 11/25/2025
# @package *Meta*
# @description This class defines an explicit permission record, linking a specific **User**
#              to a **Portfolio** they do not own and assigning them a defined level of access.
#              It is the mechanism for sharing portfolio views and management rights.
# @category *Model*
#
# Usage:: - *[What]* This code block manages the rules for granting another user access to a **Portfolio** record.
#         - *[How]* It establishes a unique link between a **User** and a **Portfolio** with an associated permission level (read or crud), preventing self-assignment.
#         - *[Why]* The application needs this class to enforce authorization policies,
#           allowing portfolio owners to securely share their data with collaborators or delegated viewers.
#
# Attributes:: - *user_id* @integer - The ID of the **User** being granted permission (the collaborator).
#              - *portfolio_id* @integer - The ID of the **Portfolio** being shared.
#              - *permission_level* @string - The level of access granted ('read' or 'crud').
#
class UserPortfolioPermission < ApplicationRecord

  # Explanation:: This defines a constant array listing all valid strings for the
  #               `permission_level` attribute, ensuring data integrity.
  PERMISSION_LEVELS = %w[read crud].freeze

  # Explanation:: This establishes a direct link, identifying the **User** who is
  #               being granted the permission (the collaborator).
  belongs_to :user

  # Explanation:: This establishes a direct link, identifying the **Portfolio**
  #               to which the permission applies (the shared resource).
  belongs_to :portfolio

  # Explanation:: This validates that the ID of the collaborating **User** is
  #               present before the permission record is saved.
  validates :user_id, presence: true

  # Explanation:: This validates that the ID of the shared **Portfolio** is
  #               present before the permission record is saved.
  validates :portfolio_id, presence: true

  # Explanation:: This validates that the `permission_level` is present and must
  #               be one of the pre-defined values in the `PERMISSION_LEVELS` list.
  validates :permission_level, presence: true, inclusion: {
    in: PERMISSION_LEVELS,
    message: "%{value} isn't a valid permission level"
  }

  # Explanation:: This ensures that a single **User** can only have one permission
  #               record for any given **Portfolio**, preventing duplicate entries.
  validates :user_id, uniqueness: {
    scope: :portfolio_id,
    message: "already has permission for this portfolio"
  }

  # Explanation:: This calls a custom private validation method to ensure that a
  #               **User** cannot grant permission to themselves (the owner).
  validate :cannot_grant_permission_to_owner

  # Explanation:: This defines a query scope that easily retrieves all permission
  #               records that grant only 'read' (view-only) access.
  scope :read_only, -> { where(permission_level: 'read') }

  # Explanation:: This defines a query scope that easily retrieves all permission
  #               records that grant 'crud' (full management) access.
  scope :crud_access, -> { where(permission_level: 'crud') }

  # Explanation:: This defines a query scope that filters permission records to
  #               only show those granted to a specific collaborating **User**.
  scope :for_user, ->(user) { where(user: user) }

  # Explanation:: This defines a query scope that filters permission records to
  #               only show those associated with a specific shared **Portfolio**.
  scope :for_portfolio, ->(portfolio) { where(portfolio: portfolio) }

  # == crud_access?
  #
  # @author Moisés Reis
  # @category *Status*
  #
  # Status:: This method quickly checks if the current permission record grants full create, read, update, and delete access.
  #          It returns true if the `permission_level` attribute is set to 'crud'.
  #
  def crud_access?
    permission_level == 'crud'
  end

  # == read_only?
  #
  # @author Moisés Reis
  # @category *Status*
  #
  # Status:: This method quickly checks if the current permission record grants only view-only access.
  #          It returns true if the `permission_level` attribute is set to 'read'.
  #
  def read_only?
    permission_level == 'read'
  end

  # == permission_description
  #
  # @author Moisés Reis
  # @category *Helper*
  #
  # Helper:: This method converts the technical `permission_level` value ('read' or 'crud') into a user-friendly, displayable string.
  #          It is used to clearly present the access level on the user interface.
  #
  def permission_description
    case permission_level
    when 'read'
      'Leitura'
    when 'crud'
      'Edição'
    else
      'Unknown access'
    end
  end

  private

  # == cannot_grant_permission_to_owner
  #
  # @author Moisés Reis
  # @category *Validation*
  #
  # Validation:: This custom validation prevents the owner of a **Portfolio** from creating a permission record that grants access to themselves.
  #              Ownership already implies full access, making a permission record redundant and incorrect.
  #
  def cannot_grant_permission_to_owner

    # Explanation:: This immediately exits the validation if either the associated **User**
    #               or **Portfolio** object is missing.
    return unless user && portfolio

    # Explanation:: This checks if the user being granted permission is the same as the
    #               user who owns the portfolio, and adds an error if they match.
    if user == portfolio.user
      errors.add(:user, "cannot grant permission to self")
    end
  end
end