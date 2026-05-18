# frozen_string_literal: true

class Forms::TextareaComponent < ApplicationComponent
  def initialize(
    form:,
    name:,
    label: nil,
    desc: nil,
    placeholder: nil,
    rows: 4,
    is_half_width: false,
    is_inactive: nil,
    is_small: false
  )
    @form = form
    @name = name
    @label = label
    @desc = desc
    @placeholder = placeholder
    @rows = rows
    @is_half_width = is_half_width
    @is_inactive = is_inactive
    @is_small = is_small
  end

  private

  attr_reader :form, :name, :label, :desc, :placeholder, :rows,
              :is_half_width, :is_inactive, :is_small

  def label_classes
    [
      "flex",
      "items-center",
      "gap-1.5",
      "text-xs",
      "font-body",
      "leading-none",
      "font-semibold",
      "select-none",
      "peer-disabled:cursor-not-allowed",
      "peer-disabled:opacity-50"
    ].join(" ")
  end

  def textarea_classes
    [
      "placeholder:text-muted",
      "bg-input",
      "border",
      "border-border",
      "w-full",
      "min-w-0",
      "rounded-base",
      "px-3",
      "py-2",
      "text-sm",
      "shadow-xs",
      "resize-none",
      "transition-[color,box-shadow]",
      "outline-none",
      "disabled:pointer-events-none",
      "disabled:cursor-not-allowed",
      "disabled:opacity-50",
      "aria-invalid:ring-danger-600/20",
      "aria-invalid:border-danger",
      "hover:bg-table-hover",
    "focus-visible:border-border",
    "focus-visible:ring-1",
    "focus-visible:ring-primary-600/20",
    "focus-visible:outline-primary-600",
    "focus-visible:outline-1",
    "focus-visible:outline-offset-2",
    ].join(" ")
  end

  def desc_classes
    [
      "flex",
      "items-center",
      "gap-1.5",
      "text-xs",
      "text-muted",
      "leading-none",
      "font-normal",
      "select-none",
      "peer-disabled:cursor-not-allowed",
      "peer-disabled:opacity-50"
    ].join(" ")
  end

  def error_classes
    [
      "!text-danger-600",
      "!bg-danger-50",
      "p-1.5",
      "px-3",
      "border",
      "border-danger-100",
      "rounded-base",
      "w-fit"
    ].join(" ")
  end

  def desc_classes_with_error
    "#{desc_classes} #{error_classes}"
  end

  def half_width_class
    is_half_width ? "!w-1/2" : ""
  end

  def describedby_id
    "#{name}-desc"
  end
end