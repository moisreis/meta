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
        bold: Rails.root.join("app/assets/fonts/PlusJakartaSans-Bold.ttf")
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
    # Explanation:: Identifies who is generating the report for auditing purposes.
    #               It defaults to 'Sistema' if no specific user is provided.
    generated_by = metadata['Gerado por'] || metadata[:user] || 'Sistema'

    # Explanation:: We use a repeat(:all) block to draw the header on every page.
    #               We use absolute coordinates to place it inside the top margin.
    pdf.repeat(:all) do
      # Explanation:: This line sets the background color to white.
      #               It prepares the canvas for drawing a clean shape
      #               underneath the header information.
      pdf.fill_color "ffffff"

      # Explanation:: This draws a white rectangle at the very top.
      #               It acts as a clean container that separates the
      #               header content from the rest of the page data.
      pdf.fill_rectangle [0, pdf.bounds.top + 70], pdf.bounds.width, 50

      # == Logo Placement Block
      #
      # @author Moisés Reis
      # @category Layout
      #
      # Category:: This block checks for a logo file and places it on the page.
      #            It positions the image slightly lower to add breathing
      #            room between the icon and the top of the container.
      #
      # Attributes:: - *File.exist?* - confirms the image file is available.
      #
      if File.exist?(logo_path)
        # Explanation:: This line places the logo at the top left.
        #               The vertical coordinate is lowered to 60 to
        #               add more space above the image.
        # pdf.image logo_path, width: 20, at: [0, pdf.bounds.top + 60]
      end

      # == Header Metadata Block
      #
      # @author Moisés Reis
      # @category Layout
      #
      # Category:: This block handles the positioning of the report header text.
      #            It ensures the title stays on the left and the metadata
      #            aligns perfectly with the right edge of the page.
      #
      # Attributes:: - *pdf.width_of* - calculates the physical size of a string.
      #
      pdf.font("JetBrains Mono") do
        pdf.font_size 7 do
          # Explanation:: This line sets the text color to a dark gray shade.
          #               It ensures the header is readable without being too
          #               harsh on the eyes compared to pure black.
          pdf.fill_color "333333"

          # Left: Report Title
          # Explanation:: This line draws the main report title at the top left.
          #               The horizontal position is set to 0 so the text
          #               touches the very edge of the left margin.
          pdf.draw_text "RELATÓRIO: #{title.upcase}", at: [0, pdf.bounds.top + 42], inline_format: true

          # Right: Metadata Info
          # Explanation:: This variable stores the name of the creator and the
          #               current time. It formats the date nicely so it is
          #               easy for any non-technical person to read.
          info_text = "GERADO POR #{generated_by.upcase} EM #{I18n.l(Time.current, format: :long).upcase}"

          # Explanation:: This line calculates the width of the info text.
          #               It measures the string based on the font size to
          #               find out exactly how much space the letters occupy.
          text_width = pdf.width_of(info_text)

          # Explanation:: This line places the metadata at the far right edge.
          #               By subtracting the text width from the total page
          #               width, the text ends exactly where the page finishes.
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
    # Explanation:: The repeat(:all) block ensures the footer appears on every page.
    #               It is placed below the bottom margin to avoid data overlap.
    pdf.repeat(:all) do
      pdf.font("JetBrains Mono") do
        pdf.font_size 8 do
          pdf.fill_color '333333'
          # Left: Record Count
          pdf.draw_text "#{data.size} REGISTRO(S)", at: [0, -40]

          # Right: Page Numbers
          # Explanation:: We use the built-in number_pages to handle counting logic.
          #               It is aligned to the right edge of the table width.
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
  #
  def format_value(value)
    # Explanation:: Returns 'N/A' if there is no information available.
    #               This ensures the table never looks empty or broken.
    return 'N/A' if value.nil?

    case value
    when BigDecimal, Float
      # Explanation:: Rounds decimal numbers to two places for currency or totals.
      #               It helps make financial data consistent and easy to read.
      format('%.2f', value)
    when Date, Time, DateTime
      # Explanation:: Converts complex timestamps into simple, local date strings.
      #               This allows users to quickly see when events occurred.
      I18n.l(value, format: :short)
    when TrueClass
      'Sim'
    when FalseClass
      'Não'
    else
      # Explanation:: Removes hidden website tags and keeps only the plain text.
      #               It prepares descriptions and names for clean document printing.
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
    # Explanation:: Searches the text for bracketed tags and deletes them.
    #               This prevents code from appearing in the final PDF report.
    text.gsub(/<\/?[^>]*>/, '').strip
  end
end