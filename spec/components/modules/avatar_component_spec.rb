# spec/components/ui/avatar_component_spec.rb
RSpec.describe Ui::AvatarComponent, type: :component do
  let(:user) { build_stubbed(:user, first_name: "Moisés", last_name: "Oliveira") }

  subject { render_inline described_class.new(user: user) }

  it "renders the avatar container" do
    subject
    expect(page).to have_css("span[data-slot='avatar']")
  end

  it "displays the user's initials" do
    subject
    expect(page).to have_css("span", text: "MO")
  end
end