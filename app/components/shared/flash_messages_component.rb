# frozen_string_literal: true

# Component responsible for rendering application flash messages in a shared
# UI format.
#
# This component maps Rails flash types into UI-friendly notification payloads
# and exposes a JSON representation for client-side consumption.
#
# @author Moisés Reis

class Shared::FlashMessagesComponent < ApplicationComponent

  # Default visibility duration for toast notifications.
  TOAST_DURATION_MS = 4000

  # Mapping of Rails flash keys to Lucide-compatible icon names.
  ICON_MAP = {
    "notice"  => "circle-check",
    "success" => "circle-check",
    "alert"   => "circle-alert",
    "error"   => "x",
    "warning" => "circle-alert",
    "info"    => "info"
  }.freeze

  # ==========================================================================
  # INITIALIZATION
  # ==========================================================================

  # @param flash [ActionDispatch::Flash::FlashHash] The current request's flash messages.
  def initialize(flash:)
    @flash = flash
  end

  # ==========================================================================
  # PUBLIC INTERFACE
  # ==========================================================================

  # Returns the list of active flash messages as a JSON string for frontend use.
  #
  # @return [String] JSON array of message objects { type, text }.
  def flash_messages_json
    @flash.map { |type, text| { type: type, text: text } }.to_json
  end

  # Returns the appropriate icon name for a given flash type.
  #
  # @param type [String, Symbol] The flash message type.
  # @return [String]
  def icon_for(type)
    ICON_MAP[type.to_s] || ICON_MAP["info"]
  end
end
