# Defines gem dependencies and version constraints using Bundler for the Rails application.
#
# This file manages core framework gems, UI libraries, utility tools, and
# environment-specific development and testing dependencies.
#
# TABLE OF CONTENTS:
#
# 1. Core Framework & Database
# 2. Authentication & Authorization
# 3. Frontend & UI Assets
# 4. Storage & Background Jobs
# 5. Utilities & Reporting
# 6. Development & Test Environment
#   6a. Shared (Development & Test)
#   6b. Development Only
#   6c. Test Only
#
# @author Moisés Reis

# =============================================================
#                1. CORE FRAMEWORK & DATABASE
# =============================================================

source "https://rubygems.org"

gem "rails", "~> 8.1.1"
gem "pg", "~> 1.1"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

# =============================================================
#               2. AUTHENTICATION & AUTHORIZATION
# =============================================================

gem "devise"
gem "cancancan"
gem "bcrypt", "~> 3.1.7"
gem "dotenv-rails"

# =============================================================
#                    3. FRONTEND & UI ASSETS
# =============================================================

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

# =============================================================
#                 4. STORAGE & BACKGROUND JOBS
# =============================================================

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "image_processing", "~> 1.2"

# =============================================================
#                  5. UTILITIES & REPORTING
# =============================================================

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
gem "victor"
gem "prawn-svg"
gem "lograge"

# =============================================================
#        6a. DEVELOPMENT & TEST — SHARED DEPENDENCIES
# =============================================================

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem 'rspec-rails',      '~> 7.0'
  gem 'factory_bot_rails'
  gem 'faker'
end

# =============================================================
#             6b. DEVELOPMENT — TOOLING & DEBUGGING
# =============================================================

group :development do
  gem "yard"
  gem "annotate"
  gem "web-console"
  gem "rack-mini-profiler"
  gem "amazing_print"
end

# =============================================================
#                6c. TEST — SYSTEM & INTEGRATION
# =============================================================

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem 'shoulda-matchers',  '~> 6.0'
  gem 'webmock'
  gem 'vcr'
  gem 'simplecov',         require: false
  gem 'database_cleaner-active_record'
  gem 'timecop'
end
