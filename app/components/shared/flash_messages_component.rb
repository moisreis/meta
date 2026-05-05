class Shared::FlashMessagesComponent < ApplicationComponent
  TOAST_DURATION_MS = 4000

  ICON_MAP = {
    "notice"  => "circle-check",
    "success" => "circle-check",
    "alert"   => "circle-alert",
    "error"   => "x",
    "warning" => "circle-alert",
    "info"    => "info"
  }.freeze

  def initialize(flash:)
    @flash = flash
  end

  private

  def flash_messages_json
    j @flash.map { |type, text| { type:, text: } }.to_json
  end
end