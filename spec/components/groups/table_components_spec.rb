# frozen_string_literal: true

require "rails_helper"

# =============================================================================
# Groups::TableColumnComponent
# =============================================================================
RSpec.describe Modules::TableColumnComponent, type: :component do
  describe "label only" do
    it "renders a th with the label" do
      render_inline(described_class.new(label: "Nome da Carteira"))
      expect(page).to have_css("th")
    end
  end

  describe "with description" do
    it "renders the sub-description span" do
      render_inline(described_class.new(label: "Valor Total", description: "Em BRL"))
      expect(page).to have_css("span.text-muted", text: "Em BRL")
    end
  end

  describe "#icon?" do
    it "returns false when icon is nil" do
      expect(described_class.new(label: "X").icon?).to be false
    end

    it "returns true when icon is present" do
      expect(described_class.new(label: "X", icon: "wallet").icon?).to be true
    end
  end

  describe "#description?" do
    it "returns false when description is nil" do
      expect(described_class.new(label: "X").description?).to be false
    end

    it "returns true when description is present" do
      expect(described_class.new(label: "X", description: "hint").description?).to be true
    end
  end
end

# =============================================================================
# Groups::TableRowComponent
# =============================================================================
RSpec.describe Modules::TableRowComponent, type: :component do
  let(:base_params) do
    {
      cells:    ["Carteira Principal", "3", "R$ 50.000,00", "Válida", "01/01/2025"],
      model_id: 42
    }
  end

  subject(:component) { described_class.new(**base_params.merge(extra)) }
  let(:extra) { {} }

  def render_component = render_inline(component)

  describe "cells" do
    it "renders one td per cell" do
      render_component
      expect(page).to have_css("td", minimum: 5)
    end

    it "renders cell content" do
      render_component
      expect(page).to have_css("td", text: "Carteira Principal")
    end

    it "applies font-medium to the first cell" do
      render_component
      expect(page).to have_css("td.font-medium", text: "Carteira Principal")
    end
  end

  describe "actions" do
    context "with no action paths" do
      it "renders an empty td placeholder" do
        render_component
        expect(page).not_to have_css("button.row-options-button")
      end
    end

    context "with show_path" do
      let(:extra) { { show_path: "/portfolios/42" } }

      it "renders the options button" do
        render_component
        expect(page).to have_css("button.row-options-button")
      end

      it "renders a Ver link" do
        render_component
        expect(page).to have_css("a[href='/portfolios/42']")
      end
    end

    context "with edit_path" do
      let(:extra) { { edit_path: "/portfolios/42/edit" } }

      it "renders an Editar link" do
        render_component
        expect(page).to have_css("a[href='/portfolios/42/edit']")
      end
    end

    context "with destroy_path" do
      let(:extra) { { destroy_path: "/portfolios/42" } }

      it "renders a Deletar button" do
        render_component
        expect(page).to have_css("button", text: /Deletar/i)
      end
    end
  end

  describe "#actions?" do
    it "returns false when all paths are nil" do
      expect(described_class.new(cells: [], model_id: 1).actions?).to be false
    end

    it "returns true when any path is present" do
      expect(described_class.new(cells: [], model_id: 1, show_path: "/x").actions?).to be true
    end
  end

  describe "#action_menu_id" do
    it "includes the model_id" do
      expect(component.action_menu_id).to eq("options-menu-42")
    end
  end
end

# =============================================================================
# Groups::TableListComponent
# =============================================================================
RSpec.describe Groups::TableListComponent, type: :component do
  subject(:component) { described_class.new(title: "Carteira") }

  describe "empty state" do
    it "renders the empty badge when no rows are added" do
      render_inline(component)
      expect(page).to have_css("p.badge", text: "Ainda não há dados.")
    end

    it "does not render a table when empty" do
      render_inline(component)
      expect(page).not_to have_css("table")
    end
  end

  describe "with columns and rows" do
    it "renders a table when rows are present" do
      render_inline(component) do |table|
        table.with_column(label: "Nome")
        table.with_row(cells: ["Carteira A"], model_id: 1)
      end
      expect(page).to have_css("table")
    end

    it "renders the correct number of th elements" do
      render_inline(component) do |table|
        table.with_column(label: "Nome")
        table.with_column(label: "Valor")
        table.with_row(cells: ["A", "B"], model_id: 1)
      end
      # 2 defined columns + 1 actions column
      expect(page).to have_css("th", count: 3)
    end

    it "renders one tr per row" do
      render_inline(component) do |table|
        table.with_column(label: "Nome")
        table.with_row(cells: ["A"], model_id: 1)
        table.with_row(cells: ["B"], model_id: 2)
      end
      expect(page).to have_css("tbody tr", count: 2)
    end
  end

  describe "#empty?" do
    it "returns true before any rows are added" do
      expect(component.empty?).to be true
    end
  end

  describe "#row_count" do
    it "reflects the number of added rows" do
      render_inline(component) do |table|
        table.with_column(label: "Nome")
        table.with_row(cells: ["A"], model_id: 1)
        table.with_row(cells: ["B"], model_id: 2)
      end
      expect(component.row_count).to eq(2)
    end
  end
end
