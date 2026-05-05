# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogoComponent, type: :component do
  subject(:component) { described_class.new(**params) }

  let(:params) { {} }

  describe "defaults" do
    it "renders with the default size" do
      render_inline(component)
      expect(page).to have_css("img[width='64'][height='64']")
    end

    it "renders with the default alt text" do
      render_inline(component)
      expect(page).to have_css("img[alt='Logo']")
    end

    it "renders logo.svg as the image source" do
      render_inline(component)
      expect(page).to have_css("img[src*='logo']")
    end

    it "wraps the image in a flex container" do
      render_inline(component)
      expect(page).to have_css("div.flex.flex-row img")
    end
  end

  describe "custom size" do
    let(:params) { { size: "128x128" } }

    it "renders with the given dimensions" do
      render_inline(component)
      expect(page).to have_css("img[width='128'][height='128']")
    end
  end

  describe "custom alt text" do
    let(:params) { { alt: "My App Logo" } }

    it "renders with the given alt text" do
      render_inline(component)
      expect(page).to have_css("img[alt='My App Logo']")
    end
  end
end