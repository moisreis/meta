# spec/components/blocks/chart_component_spec.rb
RSpec.describe Blocks::ChartComponent, type: :component do
  let(:title)  { "Evolução Patrimonial" }
  let(:source) { [1, 2, 3] }

  subject do
    render_inline described_class.new(title: title, data_source: source) do
      "<canvas id='test-chart'></canvas>".html_safe
    end
  end

  it "renders the chart title" do
    subject
    expect(page).to have_css("h3", text: title)
  end

  it "renders the chart content when data is present" do
    subject
    expect(page).to have_css("canvas#test-chart")
  end

  it "renders the empty state when the collection is empty" do
    render_inline described_class.new(title: title, data_source: [])
    expect(page).to have_text("Nenhum dado disponível")
  end

  it "renders the meta label when provided" do
    render_inline described_class.new(title: title, data_source: source, meta: "2026")
    expect(page).to have_text("2026")
  end

  it "omits the meta label when not provided" do
    subject
    expect(page).not_to have_css("span.tracking-wide")
  end

  it "sets the data-chart-id attribute when an id is given" do
    render_inline described_class.new(title: title, data_source: source, id: "patrimony-chart")
    expect(page).to have_css("[data-chart-id='patrimony-chart']")
  end
end