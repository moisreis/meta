class Layout::DashboardWrapperComponent < ApplicationComponent
  VALID_VIEWS = %w[form show index].freeze

  def initialize(page_title:, page_desc: nil, current_view: "form")
    @page_title   = page_title
    @page_desc    = page_desc
    @current_view = VALID_VIEWS.include?(current_view) ? current_view : "form"
  end
end