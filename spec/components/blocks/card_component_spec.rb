# frozen_string_literal: true

require "rails_helper"

RSpec.describe Blocks::CardComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:params)        { {} }
  let(:slot_content)  { "<span>$12,400</span>" }

  def render_component(html = slot_content)
    render_inline(component) { html.html_safe }
  end

  # ---------------------------------------------------------------------------
  # Defaults
  # ---------------------------------------------------------------------------
  describe "defaults" do
    it "renders the card wrapper" do
      render_component
      expect(page).to have_css("div.rounded-base.border.bg-white")
    end

    it "applies the default dot color" do
      render_component
      expect(page).to have_css("span.bg-neutral-300")
    end

    it "renders yielded content" do
      render_component
      expect(page).to have_css("span", text: "$12,400")
    end

    it "renders spacer when badge is absent" do
      render_component
      expect(page).to have_css("div.h-3\\.5")
    end

    it "does not render badge when absent" do
      render_component
      expect(page).not_to have_css("div.badge")
    end
  end

  # ---------------------------------------------------------------------------
  # Status
  # ---------------------------------------------------------------------------
  describe "status" do
    Blocks::CardComponent::STATUSES.each do |status|
      context "with #{status}" do
        let(:params) { { status: status } }

        it "applies correct class" do
          render_component
          css = Blocks::CardComponent::DOT_COLORS.fetch(status)
          expect(page).to have_css("span.#{css.tr('-', '\\-')}")
        end
      end
    end

    it "raises error for invalid status" do
      expect {
        described_class.new(status: :invalid)
      }.to raise_error(ArgumentError)
    end
  end

  # ---------------------------------------------------------------------------
  # Title
  # ---------------------------------------------------------------------------
  describe "title" do
    let(:params) { { title: "Monthly Revenue" } }

    it "renders title" do
      render_component
      expect(page).to have_css("p", text: "Monthly Revenue")
    end
  end

  # ---------------------------------------------------------------------------
  # Badge
  # ---------------------------------------------------------------------------
  describe "badge_text" do
    context "when present" do
      let(:params) { { badge_text: "vs last month" } }

      it "renders badge" do
        render_component
        expect(page).to have_css("div.badge")
      end

      it "renders text" do
        render_component
        expect(page).to have_text("vs last month")
      end

      it "does not render spacer" do
        render_component
        expect(page).not_to have_css("div.h-3\\.5")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Badge Icon
  # ---------------------------------------------------------------------------
  describe "badge_icon" do
    context "when present" do
      let(:params) { { badge_text: "updated", badge_icon: "calendar" } }

      it "renders icon container" do
        render_component
        expect(page).to have_css("span[class*='svg']")
      end
    end

    context "when absent" do
      let(:params) { { badge_text: "updated" } }

      it "does not render icon" do
        render_component
        expect(page).not_to have_css("span[class*='svg']")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Predicates
  # ---------------------------------------------------------------------------
  describe "#show_badge?" do
    it "returns false when absent" do
      expect(described_class.new.show_badge?).to be false
    end

    it "returns true when present" do
      expect(described_class.new(badge_text: "x").show_badge?).to be true
    end
  end

  describe "#show_badge_icon?" do
    it "returns false when absent" do
      expect(described_class.new.show_badge_icon?).to be false
    end

    it "returns true when present" do
      expect(described_class.new(badge_icon: "x").show_badge_icon?).to be true
    end
  end

  # ---------------------------------------------------------------------------
  # dot_color
  # ---------------------------------------------------------------------------
  describe "#dot_color" do
    it "returns correct class" do
      component = described_class.new(status: :success)
      expect(component.dot_color).to eq("bg-success-500")
    end
  end
end