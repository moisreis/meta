# spec/components/groups/chart_list_component_spec.rb
RSpec.describe Groups::ChartListComponent, type: :component do
  let(:data_source) { [{ name: "Jan", value: 100 }] }
  let(:defaults) do
    { chart_type: "line_chart", chart_title: "Test", data_source: data_source }
  end

  it "renders the chart title via ChartComponent" do
    render_inline described_class.new(**defaults)
    expect(page).to have_css("h3", text: "Test")
  end

  it "generates a stable chart id when none is given" do
    render_inline described_class.new(**defaults)
    expect(page).to have_css("[data-chart-id^='chart-']")
  end

  it "uses the provided chart id when given" do
    render_inline described_class.new(**defaults, chart_id: "my-chart")
    expect(page).to have_css("[data-chart-id='my-chart']")
  end

  it "raises when an unpermitted chart type is given" do
    expect {
      render_inline described_class.new(**defaults, chart_type: "system")
    }.to raise_error(ArgumentError, /Unpermitted chart type/)
  end

  it "renders the empty state when data_source is empty" do
    render_inline described_class.new(**defaults, data_source: [])
    expect(page).to have_text("Nenhum dado disponível")
  end
end