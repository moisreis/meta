# frozen_string_literal: true

# Gemfile
#
# Defines all application dependencies managed by Bundler.
#
# Gems are organized by runtime and environment-specific groups
# to provide a clear separation of responsibilities.
#
# @author  Moisés Reis

# == Sources =================================================================

source "https://rubygems.org"


# == Runtime Dependencies ====================================================

# -- Core Framework ----------------------------------------------------------

gem "rails", "~> 8.1.1"
gem "pg", "~> 1.1"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false

# -- Authentication & Authorization ------------------------------------------

gem "devise"
gem "cancancan"
gem "bcrypt", "~> 3.1.7"
gem "dotenv-rails"

# -- Frontend ----------------------------------------------------------------

gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.0"
gem "inline_svg"
gem "breadcrumbs_on_rails"
gem "chartkick"
gem "groupdate"
gem "inputmask-rails"

# -- Solid Stack -------------------------------------------------------------

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "image_processing", "~> 1.2"

# -- Server & Deployment -----------------------------------------------------

gem "puma", ">= 5.0"
gem "kamal", require: false
gem "thruster", require: false

# -- Data & Export -----------------------------------------------------------

gem "jbuilder"
gem "ransack"
gem "kaminari"
gem "rails-i18n"
gem "rubyzip"
gem "csv"

# -- PDF Generation ----------------------------------------------------------

gem "prawn"
gem "prawn-table"
gem "prawn-svg"
gem "victor"

# -- Observability & Utilities -----------------------------------------------

gem "view_component"
gem "bullet"
gem "rails_semantic_logger"
gem "ruby-progressbar"
gem "amazing_print"


# == Development & Test ======================================================

group :development, :test do

  # -- Debugging & Security --------------------------------------------------

  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false

  # -- Test Data -------------------------------------------------------------

  gem "factory_bot_rails"
  gem "faker"

end


# == Development =============================================================

group :development do

  # -- Documentation ---------------------------------------------------------

  gem "yard"

  # -- Developer Tooling -----------------------------------------------------

  gem "annotate"
  gem "web-console"
  gem "rack-mini-profiler"

end


# == Test ====================================================================

group :test do

  # -- Integration Testing ---------------------------------------------------

  gem "capybara"
  gem "selenium-webdriver"

  # -- Matchers & Test Utilities ---------------------------------------------

  gem "shoulda-matchers", "~> 6.0"
  gem "webmock"
  gem "vcr"
  gem "simplecov", require: false
  gem "database_cleaner-active_record"
  gem "timecop"

end