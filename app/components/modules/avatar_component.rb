class Modules::AvatarComponent < ApplicationComponent

  def initialize(user:)
    validate_user!(user)
    @user = user
  end

  def initials
    "#{@user.first_name.first}#{@user.last_name.first}".upcase
  end

  private

  def validate_user!(user)
    unless user.respond_to?(:first_name) && user.respond_to?(:last_name)
      raise ArgumentError, "User must respond to :first_name and :last_name"
    end
  end
end