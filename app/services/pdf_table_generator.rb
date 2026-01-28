# === pdf_table_generator.rb
#
# @author Moisés Reis
# @added 01/03/2026
# @package Services
# @description A reusable service for generating PDF exports of data tables
#              with custom branding, metadata, and model-agnostic data rendering.
# @category Service
#
# Usage:: - [What] Generates formatted PDF documents from ActiveRecord collections
#         - [How] Accepts column definitions, data, and metadata to build PDFs
#         - [Why] Provides consistent, professional PDF exports across all models
#
# Attributes:: - **title** @String - Main document title
#              - **subtitle** @String - Optional document subtitle or description
#              - **columns** @Array - Column definitions including header and key
#              - **data** @Collection - The records to be rendered in the table
#              - **metadata** @Hash - Extra information like user and date
#              - **logo_path** @String - Path to the image file for the header logo
#

class PdfTableGenerator
  require 'prawn'
  require 'prawn/table'

  # Explanation:: This accessor provides read-only access to the document and its
  #               configuration, ensuring external objects can inspect settings.
  #               It maintains the internal state of the PDF generation process.
  attr_reader :pdf, :title, :subtitle, :columns, :data, :metadata, :logo_path

  # == initialize
  #
  # @author Moisés Reis
  # @category Setup
  #
  # Setup:: Prepares the generator by setting up the document layout and fonts.
  #
  # Attributes:: - *title* - Main document title.
  #              - *columns* - Definitions for table headers and data keys.
  #              - *data* - The collection of records to be exported.
  #
  def initialize(title:, columns:, data:, subtitle: nil, metadata: {}, logo_path: nil)
    # Explanation:: Assigns the title that appears at the top of the document.
    #               This helps the user identify the purpose of the report.
    @title = title
    @subtitle = subtitle
    @columns = columns
    @data = data
    @metadata = metadata
    @logo_path = logo_path || Rails.root.join('app', 'assets', 'images', 'logo.png')

    # Explanation:: Creates a new landscape A4 document with specific margins.
    #               The margins are set to 80 to leave room for the header and footer.
    @pdf = Prawn::Document.new(
      page_size: 'A4',
      page_layout: :landscape,
      margin: [80, 36, 80, 36]
    )

    configure_fonts
  end

  # == generate
  #
  # @author Moisés Reis
  # @category Generation
  #
  # Generation:: This method runs the step-by-step process of building the document.
  #            It puts together the header, data, and footer before finishing.
  #
  def generate
    render_header
    render_table
    render_footer
    pdf.render
  end

  private

  # == configure_fonts
  #
  # @author Moisés Reis
  # @category Setup
  #
  # Setup:: Registers custom font families for the document to use.
  #
  def configure_fonts
    # Explanation:: Updates the PDF font registry with specific local TTF files.
    #               This ensures the document uses professional branding typography.
    pdf.font_families.update(
      "JetBrains Mono" => {
        normal: Rails.root.join("app/assets/fonts/JetBrainsMono-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/JetBrainsMono-Bold.ttf")
      },
      "Plus Jakarta Sans" => {
        normal: Rails.root.join("app/assets/fonts/PlusJakartaSans-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/PlusJakartaSans-Bold.ttf"),
        italic: Rails.root.join("app/assets/fonts/PlusJakartaSans-Italic.ttf")
      }
    )
  end

  # == render_header
  #
  # @author Moisés Reis
  # @category Rendering
  #
  # Rendering:: This method ensures the header is repeated on every page.
  #            It draws a background bar and places the logo and system info.
  #
  def render_header
    generated_by = metadata['Gerado por'] || metadata[:user] || 'Sistema'

    pdf.repeat(:all) do
      pdf.fill_color "ffffff"
      pdf.fill_rectangle [0, pdf.bounds.top + 70], pdf.bounds.width, 50

      pdf.font("JetBrains Mono") do
        pdf.font_size 7 do
          pdf.fill_color "333333"
          pdf.draw_text "RELATÓRIO: #{title.upcase}", at: [0, pdf.bounds.top + 42], inline_format: true

          info_text = "GERADO POR #{generated_by.upcase} EM #{I18n.l(Time.current, format: :long).upcase}"
          text_width = pdf.width_of(info_text)
          pdf.draw_text info_text, at: [pdf.bounds.width - text_width, pdf.bounds.top + 42]
        end
      end
    end
  end

  # == render_footer
  #
  # @author Moisés Reis
  # @category Rendering
  #
  # Rendering:: This method ensures the footer is repeated on every page.
  #            It draws a bottom bar with record count and page numbers.
  #
  def render_footer
    pdf.repeat(:all) do
      pdf.font("JetBrains Mono") do
        pdf.font_size 8 do
          pdf.fill_color '333333'
          pdf.draw_text "#{data.size} REGISTRO(S)", at: [0, -40]
          pdf.number_pages "<page> DE <total>", { at: [pdf.bounds.width - 60, -40] }
        end
      end
    end
  end

  # == render_table
  #
  # @author Moisés Reis
  # @category Rendering
  #
  # Rendering:: Draws the main data table, stretching it across the page width.
  #
  def render_table
    table_data = [columns.map { |col| col[:header] }]

    data.each do |record|
      table_data << columns.map { |col| extract_value(record, col[:key]) }
    end

    pdf.table(
      table_data,
      header: true,
      width: pdf.bounds.width,
      cell_style: {
        inline_format: true,
        borders: [:bottom],
        border_color: 'e9e9e9',
        border_width: 0,
        padding: [4, 0],
        size: 7
      }
    ) do
      row(0).font = 'Plus Jakarta Sans'
      row(0).font_style = :bold
      row(0).text_color = '333333'
      row(0).background_color = 'ffffff'

      rows(1..-1).font = 'Plus Jakarta Sans'
      rows(1..-1).text_color = '8a8a8a'
    end
  end

  # == extract_value
  #
  # @author Moisés Reis
  # @category Logic
  #
  # Logic:: This block pulls information from a record using a name or code.
  #         It ensures the correct data is found before it is formatted.
  #
  # Attributes:: - *record* - the specific item being looked at in the list.
  #              - *key* - the identifier used to find the right information.
  #
  def extract_value(record, key)
    case key
    when Symbol, String
      value = record.public_send(key)
    when Proc
      value = key.call(record)
    else
      value = nil
    end

    format_value(value)
  end

  # == format_value
  #
  # @author Moisés Reis
  # @category Utility
  #
  # Utility:: Changes raw data into a friendly text format for the reader.
  #          It adds colors to negatives and styles missing information.
  #
  def format_value(value)
    # Explanation:: This block identifies missing data or specific 'N/A' strings
    #               and wraps them in italic tags for a distinct visual style.
    return "<i>N/A</i>" if value.nil? || value.to_s.strip.upcase == 'N/A'

    case value
    when Numeric
      formatted_num = format('%.2f', value)
      # Explanation:: This check looks for numbers below zero and colors them red.
      #               It helps users immediately spot negative balances or losses.
      value < 0 ? "<color rgb='ff0000'>#{formatted_num}</color>" : formatted_num
    when String
      # Explanation:: This condition checks if a string represents a negative value.
      #               It colors the text red if a minus sign is detected at the start.
      if value.strip.start_with?('-')
        "<color rgb='ff0000'>#{value}</color>"
      else
        strip_html(value)
      end
    when Date, Time, DateTime
      I18n.l(value, format: :short)
    when TrueClass
      'Sim'
    when FalseClass
      'Não'
    else
      strip_html(value.to_s)
    end
  end

  # == strip_html
  #
  # @author Moisés Reis
  # @category Utility
  #
  # Utility:: Cleans up strings by removing any technical HTML tags.
  #
  def strip_html(text)
    text.gsub(/<\/?[^>]*>/, '').strip
  end
end