# frozen_string_literal: true

require "rails_helper"

RSpec.describe SectionComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:params)       { {} }
  let(:slot_content) { "<div>card</div>" }

  def render_component
    render_inline(component) { slot_content.html_safe }
  end

  # ---------------------------------------------------------------------------
  # Defaults
  # ---------------------------------------------------------------------------
  describe "defaults" do
    it "renders a section element" do
      render_component
      expect(page).to have_css("section")
    end

    it "renders the grid with the 2-column default" do
      render_component
      expect(page).to have_css("div.grid.grid-cols-1.md\\:grid-cols-2")
    end

    it "renders yielded content inside the grid" do
      render_component
      expect(page).to have_css("div.grid div", text: "card")
    end

    it "does not render a header when title is absent" do
      render_component
      expect(page).not_to have_css("p.font-mono")
    end

    it "does not render an action button when action is absent" do
      render_component
      expect(page).not_to have_css("a.button")
    end
  end

  # ---------------------------------------------------------------------------
  # Grid columns
  # ---------------------------------------------------------------------------
  describe "grid columns" do
    SectionComponent::GRID_CLASSES.each do |cols, css|
      context "with columns: #{cols}" do
        let(:params) { { columns: cols } }

        it "applies the correct grid class" do
          render_component
          # Check the first class token which is always grid-cols-1
          expect(page).to have_css("div.grid")
        end
      end
    end

    context "with an out-of-range column value" do
      let(:params) { { columns: 99 } }

      it "falls back to the default grid class" do
        render_component
        expect(page).to have_css("div.grid")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Title
  # ---------------------------------------------------------------------------
  describe "title" do
    let(:params) { { title: "Portfólios" } }

    it "renders the title text" do
      render_component
      expect(page).to have_css("p.font-mono", text: "Portfólios")
    end

    it "renders the hidden section-desc container" do
      render_component
      expect(page).to have_css("div.section-desc#portf-lios-desc")
    end

    it "does not render the description paragraph when description is absent" do
      render_component
      expect(page).not_to have_css("p.font-body")
    end
  end

  # ---------------------------------------------------------------------------
  # Description
  # ---------------------------------------------------------------------------
  describe "description" do
    let(:params) { { title: "Portfólios", description: "Visão geral" } }

    it "renders the description paragraph" do
      render_component
      expect(page).to have_css("p.font-body", text: "Visão geral")
    end

    it "renders the description inside the hidden container" do
      render_component
      expect(page).to have_css("div.section-desc h2", text: "Visão geral")
    end
  end

  # ---------------------------------------------------------------------------
  # Action button
  # ---------------------------------------------------------------------------
  describe "action button" do
    let(:action) do
      { route: "/applications/new", label: "Nova Aplicação", icon: "plus", id: "new-app-btn" }
    end
    let(:params) { { action: action } }

    it "renders the action link" do
      render_component
      expect(page).to have_css("a.button.button-small.button-outline")
    end

    it "renders the button label" do
      render_component
      expect(page).to have_css("span", text: "Nova Aplicação")
    end

    it "applies the correct href" do
      render_component
      expect(page).to have_css("a[href='/applications/new']")
    end

    it "applies the button id" do
      render_component
      expect(page).to have_css("a#new-app-btn")
    end

    context "when icon is absent" do
      let(:action) { { route: "/applications/new", label: "Nova Aplicação" } }

      it "does not render an svg tag" do
        render_component
        expect(page).not_to have_css("svg")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Predicate helpers
  # ---------------------------------------------------------------------------
  describe "#title?" do
    it "returns false when title is nil" do
      expect(described_class.new.title?).to be false
    end

    it "returns true when title is present" do
      expect(described_class.new(title: "Test").title?).to be true
    end
  end

  describe "#description?" do
    it "returns false when description is nil" do
      expect(described_class.new.description?).to be false
    end

    it "returns true when description is present" do
      expect(described_class.new(description: "Test").description?).to be true
    end
  end

  describe "#action?" do
    it "returns false when action is nil" do
      expect(described_class.new.action?).to be false
    end

    it "returns true when action is present" do
      expect(described_class.new(action: { route: "/", label: "Go" }).action?).to be true
    end
  end

  describe "#grid_classes" do
    it "returns the correct class for a known column count" do
      expect(described_class.new(columns: 3).grid_classes).to eq("grid-cols-1 md:grid-cols-2 lg:grid-cols-3")
    end

    it "returns the fallback class for an unknown column count" do
      expect(described_class.new(columns: 99).grid_classes).to eq(SectionComponent::FALLBACK_GRID_CLASS)
    end
  end

  describe "#description_dom_id" do
    it "parameterizes the title for use as a DOM id" do
      expect(described_class.new(title: "Meu Portfólio").description_dom_id).to eq("meu-portf-lio-desc")
    end
  end
end