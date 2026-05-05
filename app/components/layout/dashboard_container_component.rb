class Layout::DashboardContainerComponent < ApplicationComponent

  def initialize(page_title:, page_desc: nil, current_view: "form")
    @page_title   = page_title
    @page_desc    = page_desc
    @current_view = current_view
  end
end