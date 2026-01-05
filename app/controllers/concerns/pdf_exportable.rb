# === PdfExportable
#
# @author Moisés Reis
# @added 01/02/2026
# @package Concerns
# @description A controller concern that adds PDF export functionality
#              to any resource with minimal configuration.
# @category Concern
#
# Usage:: Include this concern in any controller and implement the required methods:
#         - pdf_export_title
#         - pdf_export_columns
#         - pdf_export_data
#
# Example::
#   class PortfoliosController < ApplicationController
#     include PdfExportable
#
#     def pdf_export_title
#       "Carteiras"
#     end
#
#     def pdf_export_columns
#       [
#         { header: "Nome", key: :name },
#         { header: "Proprietário", key: ->(p) { p.user.full_name } }
#       ]
#     end
#
#     def pdf_export_data
#       @portfolios = Portfolio.for_user(current_user)
#     end
#   end

module PdfExportable
  extend ActiveSupport::Concern

  included do
    # Explanation:: Adds the export action to the controller's available actions
    before_action :set_export_data, only: [:export]
  end

  # == export
  #
  # @author Moisés Reis
  # @category Action
  #
  # Action:: Handles PDF export requests and streams the generated PDF to the browser.
  #
  def export
    # Explanation:: Calls the PDF generator with controller-specific configuration
    pdf = PdfTableGenerator.new(
      title: pdf_export_title,
      subtitle: pdf_export_subtitle,
      columns: pdf_export_columns,
      data: pdf_export_data,
      metadata: pdf_export_metadata,
      logo_path: pdf_export_logo_path,
    ).generate

    # Explanation:: Sends the PDF file to the browser with proper headers
    send_data pdf,
              filename: pdf_export_filename,
              type: 'application/pdf',
              disposition: 'attachment'
  end

  private

  # == set_export_data
  #
  # @author Moisés Reis
  # @category Setup
  #
  # Setup:: Prepares data for export, applying the same filters as the index action.
  #
  def set_export_data
    # Explanation:: Controllers can override this to set @models or similar
    # This default implementation does nothing, allowing flexibility
  end

  # == pdf_export_filename
  #
  # @author Moisés Reis
  # @category Configuration
  #
  # Configuration:: Generates the filename for the downloaded PDF.
  #
  def pdf_export_filename
    "#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf"
  end

  # == pdf_export_subtitle
  #
  # @author Moisés Reis
  # @category Configuration
  #
  # Configuration:: Optional subtitle for the PDF document.
  #
  def pdf_export_subtitle
    nil
  end

  # == pdf_export_metadata
  #
  # @author Moisés Reis
  # @category Configuration
  #
  # Configuration:: Additional metadata to include in the PDF header.
  #
  def pdf_export_metadata
    {
      'Gerado por' => current_user&.full_name || 'Sistema',
      'E-mail' => current_user&.email || 'N/A'
    }
  end

  # == pdf_export_logo_path
  #
  # @author Moisés Reis
  # @category Configuration
  #
  # Configuration:: Path to the logo image file.
  #
  def pdf_export_logo_path
    Rails.root.join('app', 'assets', 'images', 'logo.png')
  end

  # == pdf_export_title
  #
  # @author Moisés Reis
  # @category Configuration
  #
  # Configuration:: Title of the PDF document. Must be implemented by including controller.
  #
  def pdf_export_title
    raise NotImplementedError, "#{self.class} must implement pdf_export_title"
  end

  # == pdf_export_columns
  #
  # @author Moisés Reis
  # @category Configuration
  #
  # Configuration:: Column definitions for the PDF table. Must be implemented by including controller.
  #
  def pdf_export_columns
    raise NotImplementedError, "#{self.class} must implement pdf_export_columns"
  end

  # == pdf_export_data
  #
  # @author Moisés Reis
  # @category Configuration
  #
  # Configuration:: Data collection to export. Must be implemented by including controller.
  #
  def pdf_export_data
    raise NotImplementedError, "#{self.class} must implement pdf_export_data"
  end
end