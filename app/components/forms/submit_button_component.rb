# frozen_string_literal: true

# Component responsible for rendering a form submit button with contextual
# labeling and icon selection based on HTTP method semantics.
#
# This component standardizes submit actions across create and update forms.
#
# @author Moisés Reis

class Forms::SubmitButtonComponent < ApplicationComponent

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param builder [ActionView::Helpers::FormBuilder] The Rails form builder instance.
  # @param method [Symbol] The HTTP method (e.g., :post, :patch, :put).
  # @param label [String, nil] Custom label; defaults based on the HTTP method.
  # @param icon [String, nil] Lucide icon name; defaults based on the HTTP method.
  def initialize(builder:, method:, label: nil, icon: nil)
    @builder = builder
    @method  = method
    @label   = label || (editing? ? "Atualizar" : "Criar")
    @icon    = icon  || (editing? ? "save"      : "plus")
  end

  # ==========================================================================
  # PRIVATE METHODS
  # ==========================================================================

  private

  # Determines if the form is in an update/edit state.
  # @return [Boolean]
  def editing?
    @method == :patch || @method == :put
  end
end
