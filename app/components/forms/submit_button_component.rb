# frozen_string_literal: true

# app/components/forms/submit_button_component.rb
#
# Component responsible for rendering a form submit button with contextual
# labeling and icon selection based on HTTP method semantics.
#
# This component standardizes submit actions across create and update forms.
#
# @author  Moisés Reis

class Forms::SubmitButtonComponent < ApplicationComponent

  # == Class Methods ==========================================================

  # Initializes the submit button component with contextual copy and icons.
  #
  # @param builder [ActionView::Helpers::FormBuilder] The Rails form builder instance.
  # @param method [Symbol] The HTTP method (e.g., :post, :patch, :put).
  # @param label [String, nil] Custom label; defaults based on the HTTP method.
  # @param icon [String, nil] Lucide icon name; defaults based on the HTTP method.
  # @return [Forms::SubmitButtonComponent]
  def initialize(builder:, method:, label: nil, icon: nil)
    @builder = builder
    @method  = method
    @label   = label || (editing? ? "Atualizar" : "Criar")
    @icon    = icon  || (editing? ? "save"      : "plus")
  end


  private


  # == Private Methods ========================================================

  # -- Contextual Predicates --------------------------------------------------

  # Determines if the form is in an update/edit state.
  #
  # @return [Boolean] True if the transaction method maps to an persistent record update.
  def editing?
    @method == :patch || @method == :put
  end

end