# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecentActivityComponent, type: :component do
  # Minimal double that satisfies the default date resolution logic.
  let(:item) do
    instance_double("Application",
      to_s:         "ACME Fund",
      request_date: Date.new(2025, 6, 1),
      created_at:   nil
    )
  end

  let(:base_params) do
    {
      title:          "Aplicações Recentes",
      collection:     [item],
      title_proc:     ->(i) { i.to_s },
      value_proc:     ->(_i) { "R$ 1.000,00" },
      sub_value_proc: ->(_i) { "10 cotas" }
    }
  end

  subject(:component) { described_class.new(**base_params.merge(extra_params)) }
  let(:extra_params)  { {} }

  def render_component
    render_inline(component)
  end

  # ---------------------------------------------------------------------------
  # Structure
  # ---------------------------------------------------------------------------
  describe "structure" do
    it "delegates to SectionComponent for the outer section" do
      render_component
      expect(page).to have_css("section")
    end

    it "renders one card row per item" do
      render_component
      expect(page).to have_css("div.grid.grid-cols-2", count: 1)
    end
  end

  # ---------------------------------------------------------------------------
  # Empty state
  # ---------------------------------------------------------------------------
  describe "empty collection" do
    let(:extra_params) { { collection: [] } }

    it "renders the empty state badge" do
      render_component
      expect(page).to have_css("p.badge", text: "Ainda não há dados.")
    end

    it "does not render any card rows" do
      render_component
      expect(page).not_to have_css("div.grid.grid-cols-2")
    end
  end

  # ---------------------------------------------------------------------------
  # Card content
  # ---------------------------------------------------------------------------
  describe "card content" do
    it "renders the title from title_proc" do
      render_component
      expect(page).to have_css("span.text-sm", text: "ACME Fund")
    end

    it "renders the value from value_proc" do
      render_component
      expect(page).to have_css("span.font-heading", text: "R$ 1.000,00")
    end

    it "renders the sub value from sub_value_proc" do
      render_component
      expect(page).to have_css("span.font-mono", text: "10 cotas")
    end
  end

  # ---------------------------------------------------------------------------
  # Color
  # ---------------------------------------------------------------------------
  describe "color classes" do
    RecentActivityComponent::COLORS.each_key do |color|
      context "with color: #{color}" do
        let(:extra_params) { { color: color } }

        it "applies a background class to the icon container" do
          render_component
          expect(page).to have_css("div.size-7.rounded-full[class*='bg-']")
        end
      end
    end

    context "with an unknown color" do
      let(:extra_params) { { color: :nonexistent } }

      it "falls back to the default color classes" do
        component_instance = described_class.new(**base_params.merge(extra_params))
        expect(component_instance.color_classes).to eq(described_class::FALLBACK_COLOR)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Icon direction
  # ---------------------------------------------------------------------------
  describe "#icon_name" do
    it "returns arrow-up-right for success" do
      c = described_class.new(**base_params.merge(color: :success))
      expect(c.icon_name).to eq("arrow-up-right")
    end

    it "returns arrow-down-left for any other color" do
      c = described_class.new(**base_params.merge(color: :danger))
      expect(c.icon_name).to eq("arrow-down-left")
    end
  end

  # ---------------------------------------------------------------------------
  # Date resolution
  # ---------------------------------------------------------------------------
  describe "#card_date" do
    it "prefers request_date when available" do
      c = described_class.new(**base_params)
      expect(c.card_date(item)).to eq(Date.new(2025, 6, 1))
    end

    it "falls back to created_at when request_date is absent" do
      fallback_item = instance_double("Log",
        request_date: nil,
        created_at:   Time.zone.parse("2025-06-01 10:00:00")
      )
      c = described_class.new(**base_params)
      expect(c.card_date(fallback_item)).to eq(Time.zone.parse("2025-06-01 10:00:00"))
    end
  end

  # ---------------------------------------------------------------------------
  # Predicate
  # ---------------------------------------------------------------------------
  describe "#empty?" do
    it "returns true when collection is empty" do
      expect(described_class.new(**base_params.merge(collection: [])).empty?).to be true
    end

    it "returns false when collection has items" do
      expect(described_class.new(**base_params).empty?).to be false
    end
  end
end