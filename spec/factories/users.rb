# Defines FactoryBot factories for the User model.
#
# This factory provides a baseline user entity with realistic generated data
# using Faker, along with traits for role-based variations.
#
# TABLE OF CONTENTS:
#   1.  Base Factory Definition
#   2.  Traits
#       2a. Admin Role
#
# @author Project Team

FactoryBot.define do
  # =============================================================
  #                  1. BASE FACTORY DEFINITION
  # =============================================================

  # Factory for creating User records with valid default attributes.
  #
  # Attributes:
  # - first_name: Random first name generated via Faker.
  # - last_name:  Random last name generated via Faker.
  # - email:      Unique email address.
  # - password:   Static password for test consistency.
  # - role:       Default role set to "user".
  #
  # @return [User] A valid, unsaved or persisted User instance depending on usage.
  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    email      { Faker::Internet.unique.email }
    password   { 'password123' }
    role       { 'user' }

    # =============================================================
    #                          2. TRAITS
    # =============================================================

    # -------------------------------------------------------------
    #                      2a. ADMIN ROLE
    # -------------------------------------------------------------

    # Overrides the default role to "admin".
    #
    # Usage:
    #   create(:user, :admin)
    #
    # @return [User] A User instance with admin privileges.
    trait :admin do
      role { 'admin' }
    end
  end
end
