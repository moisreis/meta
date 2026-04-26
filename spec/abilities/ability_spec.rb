# Tests the Ability model, defining authorization rules using CanCanCan.
#
# This spec verifies permission boundaries for different user roles,
# ensuring correct access control for admin users, regular users,
# and guests (unauthenticated users).
#
# TABLE OF CONTENTS:
#   1.  Admin Permissions
#   2.  Regular User Permissions
#   3.  Guest Permissions
#
# @author Moisés Reis

require 'cancan/matchers'

RSpec.describe Ability, type: :model do
  # Initializes Ability with the given user.
  #
  # @return [Ability]
  subject(:ability) { Ability.new(user) }

  # =============================================================
  #                   1. ADMIN PERMISSIONS
  # =============================================================

  context "when user is admin" do
    let(:user) { build(:user, :admin) }

    # Admins can perform any action on any resource.
    #
    # @return [void]
    it "can manage everything" do
      expect(ability).to be_able_to(:manage, :all)
    end
  end

  # =============================================================
  #                2. REGULAR USER PERMISSIONS
  # =============================================================

  context "when user is a regular user" do
    let(:user)      { create(:user) }
    let(:portfolio) { create(:portfolio, user: user) }

    # Allows reading owned portfolio.
    #
    # @return [void]
    it "can read their own portfolio" do
      expect(ability).to be_able_to(:read, portfolio)
    end

    # Allows full management of owned portfolio.
    #
    # @return [void]
    it "can manage their own portfolio" do
      expect(ability).to be_able_to(:manage, portfolio)
    end

    # Prevents managing portfolios owned by others.
    #
    # @return [void]
    it "cannot manage another user's portfolio" do
      other_portfolio = create(:portfolio)

      expect(ability).not_to be_able_to(:manage, other_portfolio)
    end

    # Allows reading own user record.
    #
    # @return [void]
    it "can read their own user record" do
      expect(ability).to be_able_to(:read, user)
    end

    # Prevents reading other user records.
    #
    # @return [void]
    it "cannot read another user's record" do
      other_user = create(:user)

      expect(ability).not_to be_able_to(:read, other_user)
    end
  end

  # =============================================================
  #                    3. GUEST PERMISSIONS
  # =============================================================

  context "when user is nil" do
    let(:user) { nil }

    # Denies access to all resources for unauthenticated users.
    #
    # @return [void]
    it "cannot access anything" do
      expect(ability).not_to be_able_to(:read, Portfolio)
    end
  end
end
