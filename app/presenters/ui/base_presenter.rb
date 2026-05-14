# frozen_string_literal: true

# Provides the foundational behavior shared across UI presenter objects.
#
# This base presenter encapsulates access to the Rails view context and
# exposes helper delegation utilities for subclasses responsible for
# presentation-layer rendering behavior.
#
# @author Moisés Reis

class Ui::BasePresenter

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # Initializes the presenter with the current Rails view context.
  #
  # @param view_context [ActionView::Base] Rails view context instance.
  def initialize(view_context)
    @view = view_context
  end

  protected

  # ==========================================================================
  # VIEW HELPERS
  # ==========================================================================

  # Returns the Rails view context helper proxy.
  #
  # This helper method provides convenient delegated access to Rails
  # rendering helpers and view utilities inside presenter subclasses.
  #
  # @return [ActionView::Base] Rails view context instance.
  def h
    @view
  end
end
