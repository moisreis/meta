class Modules::CopyrightComponent < ApplicationComponent

  def initialize
    super()
  end

  def current_year
    Time.current.year
  end
end