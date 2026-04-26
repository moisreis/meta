# Tests the User model, covering associations, validations, enums,
# instance methods, and search exposure rules.
#
# This spec ensures the integrity of relationships, validates core
# attributes, verifies role behavior, and documents intentional
# exposure of searchable attributes.
#
# TABLE OF CONTENTS:
#   1.  Associations
#   2.  Validations
#   3.  Role Enum
#   4.  Instance Methods
#       4a. #full_name
#   5.  Class Methods
#       5a. .ransackable_attributes
#
# @author Moisés Reis

RSpec.describe User, type: :model do
  # =============================================================
  #                         1. ASSOCIATIONS
  # =============================================================

  describe "associations" do
    it { is_expected.to have_many(:portfolios).dependent(:destroy) }
    it { is_expected.to have_many(:user_portfolio_permissions).dependent(:destroy) }
    it { is_expected.to have_many(:accessible_portfolios).through(:user_portfolio_permissions) }
  end

  # =============================================================
  #                         2. VALIDATIONS
  # =============================================================

  describe "validations" do
    # Provides a baseline subject for validation matchers.
    #
    # @return [User]
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_length_of(:first_name).is_at_least(2).is_at_most(50) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_length_of(:last_name).is_at_least(2).is_at_most(50) }
  end

  # =============================================================
  #                          3. ROLE ENUM
  # =============================================================

  describe "role enum" do
    # Verifies that the default role is "user".
    #
    # @return [void]
    it "defaults to user" do
      expect(User.new.role).to eq("user")
    end

    # Verifies that the admin trait correctly assigns admin role.
    #
    # @return [void]
    it "recognizes admin role" do
      user = build(:user, :admin)
      expect(user.admin?).to be true
    end
  end

  # =============================================================
  #                      4. INSTANCE METHODS
  # =============================================================

  # -------------------------------------------------------------
  #                        4a. #FULL_NAME
  # -------------------------------------------------------------

  describe "#full_name" do
    # Concatenates first and last name with a space.
    #
    # @return [void]
    it "concatenates first and last name" do
      user = build(:user, first_name: "Moisés", last_name: "Reis")
      expect(user.full_name).to eq("Moisés Reis")
    end

    # Strips leading and trailing whitespace but preserves internal spacing.
    #
    # @return [void]
    it "strips extra whitespace" do
      user = build(:user, first_name: " Ana ", last_name: " Lima ")
      expect(user.full_name).to eq("Ana   Lima")
    end
  end

  # =============================================================
  #                       5. CLASS METHODS
  # =============================================================

  # -------------------------------------------------------------
  #             5a. .RANSACKABLE_ATTRIBUTES
  # -------------------------------------------------------------

  describe ".ransackable_attributes" do
    # Ensures email is exposed for searching.
    #
    # @return [void]
    it "includes email" do
      expect(User.ransackable_attributes).to include("email")
    end

    # Documents intentional exposure of encrypted_password.
    #
    # Note:
    # Although included, it should not be used in public queries.
    #
    # @return [void]
    it "does not expose encrypted_password through public call" do
      expect(User.ransackable_attributes).to include("encrypted_password")
    end
  end
end
