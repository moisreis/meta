class PdfTableGenerator
  require 'prawn'
  require 'prawn/table'

  attr_reader :pdf, :title, :subtitle, :columns, :data, :metadata, :logo_path

  def initialize(title:, columns:, data:, subtitle: nil, metadata: {}, logo_path: nil)

    @title = title
    @subtitle = subtitle
    @columns = columns
    @data = data
    @metadata = metadata
    @logo_path = logo_path || Rails.root.join('app', 'assets', 'images', 'logo.png')

    @pdf = Prawn::Document.new(
      page_size: 'A4',
      page_layout: :landscape,
      margin: [80, 36, 80, 36]
    )

    configure_fonts
  end

  def generate
    render_header
    render_table
    render_footer
    pdf.render
  end

  private

  def configure_fonts

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

  def format_value(value)

    return "<i>N/A</i>" if value.nil? || value.to_s.strip.upcase == 'N/A'

    case value
    when Numeric
      formatted_num = format('%.2f', value)

      value < 0 ? "<color rgb='ff0000'>#{formatted_num}</color>" : formatted_num
    when String

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

  def strip_html(text)
    text.gsub(/<\/?[^>]*>/, '').strip
  end
end