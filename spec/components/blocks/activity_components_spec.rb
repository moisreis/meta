# frozen_string_literal: true

require "rails_helper"

# =============================================================================
# Groups::ActivityItemComponent
# =============================================================================
RSpec.describe Blocks::ActivityItemComponent, type: :component do
  let(:base_params) do
    {
      title: "Fundo XP Crédito",
      value: "R$ 10.000,00",
      sub:   "Carteira Principal",
      date:  Date.new(2025, 6, 1),
      color: :success
    }
  end

  subject(:component) { described_class.new(**base_params.merge(extra)) }
  let(:extra) { {} }

  def render_component = render_inline(component)

  # ---------------------------------------------------------------------------
  # Content
  # ---------------------------------------------------------------------------
  describe "content" do
    it "renders the title" do
      render_component
      expect(page).to have_css("span.text-sm", text: "Fundo XP Crédito")
    end

    it "renders the primary value" do
      render_component
      expect(page).to have_css("span.font-heading", text: "R$ 10.000,00")
    end

    it "renders the sub label" do
      render_component
      expect(page).to have_css("span.font-mono", text: "Carteira Principal")
    end
  end

  # ---------------------------------------------------------------------------
  # Color classes
  # ---------------------------------------------------------------------------
  describe "#color_classes" do
    described_class::COLORS.each_key do |color|
      context "with color: #{color}" do
        let(:extra) { { color: color } }

        it "returns a hash with :bg, :stroke, and :text keys" do
          expect(component.color_classes.keys).to contain_exactly(:bg, :stroke, :text)
        end
      end
    end

    context "with an unknown color" do
      let(:extra) { { color: :unknown } }

      it "falls back to FALLBACK_COLOR" do
        expect(component.color_classes).to eq(described_class::FALLBACK_COLOR)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Icon direction
  # ---------------------------------------------------------------------------
  describe "#icon_name" do
    it "returns arrow-up-right for :success" do
      expect(described_class.new(**base_params.merge(color: :success)).icon_name)
        .to eq("arrow-up-right")
    end

    it "returns arrow-down-left for any other color" do
      expect(described_class.new(**base_params.merge(color: :danger)).icon_name)
        .to eq("arrow-down-left")
    end
  end

  # ---------------------------------------------------------------------------
  # Date
  # ---------------------------------------------------------------------------
  describe "#formatted_date" do
    it "does not raise when date is nil" do
      c = described_class.new(**base_params.merge(date: nil))
      expect { c.formatted_date }.not_to raise_error
    end
  end
end

# =============================================================================
# Groups::RecentActivityComponent
# =============================================================================
RSpec.describe Groups::RecentActivityComponent, type: :component do
  subject(:component) { described_class.new(title: "Aplicações", **extra) }
  let(:extra) { {} }

  def item_params(overrides = {})
    {
      title: "Fundo ABC",
      value: "R$ 5.000,00",
      sub:   "Carteira Teste",
      date:  Date.new(2025, 1, 15),
      color: :success
    }.merge(overrides)
  end

  # ---------------------------------------------------------------------------
  # Empty state
  # ---------------------------------------------------------------------------
  describe "empty state" do
    it "renders the empty badge when no items are provided" do
      render_inline(component)
      expect(page).to have_css("p.badge", text: "Ainda não há dados.")
    end

    it "does not render any item rows when empty" do
      render_inline(component)
      expect(page).not_to have_css("div.grid.grid-cols-2")
    end
  end

  # ---------------------------------------------------------------------------
  # With items
  # ---------------------------------------------------------------------------
  describe "with items" do
    it "renders item rows for each with_item call" do
      render_inline(component) do |c|
        c.with_item(**item_params)
        c.with_item(**item_params(title: "Fundo DEF"))
      end

      expect(page).to have_css("div.grid.grid-cols-2", count: 2)
    end

    it "does not render the empty badge when items are present" do
      render_inline(component) { |c| c.with_item(**item_params) }
      expect(page).not_to have_css("p.badge")
    end
  end

  # ---------------------------------------------------------------------------
  # empty? predicate
  # ---------------------------------------------------------------------------
  describe "#empty?" do
    it "returns true before any items are added" do
      expect(component.empty?).to be true
    end
  end

  # ---------------------------------------------------------------------------
  # Section delegation
  # ---------------------------------------------------------------------------
  describe "section wrapper" do
    it "renders a section element" do
      render_inline(component)
      expect(page).to have_css("section")
    end
  end
end
