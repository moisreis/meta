# frozen_string_literal: true

# app/presenters/ui/base_presenter.rb
#
# Ui namespace containing base infrastructure for presenter objects.
#
# Base class for UI presenters.
# Provides access to Rails view helpers via a consistent interface.
#
# @author Moisés Reis
class Ui::BasePresenter

  # =============================================================
  #                      1. INITIALIZATION
  # =============================================================

  # @param view_context [ActionView::Base] Rails view context providing helper methods.
  def initialize(view_context)
    @view = view_context
  end

  protected

  # =============================================================
  #                  2a. VIEW HELPER ACCESSOR
  # =============================================================

  # Provides access to Rails view helpers through a consistent interface.
  #
  # @return [ActionView::Base] The wrapped view context.
  def h
    @view
  end
end
