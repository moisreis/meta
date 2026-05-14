# Defines gem dependencies and version constraints for the Rails application.
#
# This file is evaluated by Bundler to resolve and install application
# dependencies across all environments, including framework components,
# UI libraries, infrastructure tooling, and development/test utilities.
#
# @author Moisés Reis

# ============================================================================
# CORE FRAMEWORK & DATABASE
# ============================================================================

source "https://rubygems.org"

gem "rails", "~> 8.1.1"
gem "pg", "~> 1.1"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false

# ============================================================================
# AUTHENTICATION & AUTHORIZATION
# ============================================================================

gem "devise"
gem "cancancan"
gem "bcrypt", "~> 3.1.7"
gem "dotenv-rails"

# ============================================================================
# FRONTEND & UI ASSETS
# ============================================================================

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

# ============================================================================
# STORAGE & BACKGROUND PROCESSING
# ============================================================================

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "image_processing", "~> 1.2"

# ============================================================================
# UTILITIES & REPORTING
# ============================================================================

gem "puma", ">= 5.0"
gem "kamal", require: false
gem "thruster", require: false
gem "jbuilder"
gem "ransack"
gem "kaminari"
gem "rails-i18n"
gem "rubyzip"
gem "csv"
gem "prawn"
gem "prawn-table"
gem "prawn-svg"
gem "victor"
gem "view_component"
gem "bullet"
gem "rails_semantic_logger"
gem "ruby-progressbar"
gem "amazing_print"

# ============================================================================
# DEVELOPMENT & TEST — SHARED DEPENDENCIES
# ============================================================================

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "factory_bot_rails"
  gem "faker"
end

# ============================================================================
# DEVELOPMENT — TOOLING & DEBUGGING
# ============================================================================

group :development do
  gem "yard"
  gem "annotate"
  gem "web-console"
  gem "rack-mini-profiler"
end

# ============================================================================
# TEST — SYSTEM & INTEGRATION
# ============================================================================

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 6.0"
  gem "webmock"
  gem "vcr"
  gem "simplecov", require: false
  gem "database_cleaner-active_record"
  gem "timecop"
end
