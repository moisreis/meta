class Forms::FieldsetComponent < ApplicationComponent

  def initialize(title:, description: nil)
    @title = title
    @description = description
  end
end