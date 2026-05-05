class Modules::LogoComponent < ApplicationComponent
  DEFAULT_SIZE = "64x64"
  DEFAULT_ALT  = "Logo"

  def initialize(size: DEFAULT_SIZE, alt: DEFAULT_ALT)
    @size = size
    @alt  = alt
  end
end