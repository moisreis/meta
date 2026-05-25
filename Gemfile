source "https://rubygems.org"

# ===============================================================
#                        CORE FRAMEWORK
# ===============================================================

gem "rails", "~> 8.1.1"
gem "pg", "~> 1.1"
gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false

# ===============================================================
#              AUTHENTICATION & AUTHORIZATION
# ===============================================================

gem "devise"
gem "cancancan"
gem "bcrypt", "~> 3.1.7"
gem "dotenv-rails"

# ===============================================================
#                     FRONTEND STACK
# ===============================================================

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

# ===============================================================
#               BACKGROUND & INFRASTRUCTURE
# ===============================================================

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "image_processing", "~> 1.2"

# ===============================================================
#                    APPLICATION SERVER
# ===============================================================

gem "puma", ">= 5.0"
gem "kamal", require: false
gem "thruster", require: false

# ===============================================================
#                 DATA / SERIALIZATION / REPORTING
# ===============================================================

gem "jbuilder"
gem "ransack"
gem "kaminari"
gem "rails-i18n"
gem "rubyzip"
gem "csv"

# ===============================================================
#                   PDF & GRAPHICS TOOLING
# ===============================================================

gem "prawn"
gem "prawn-table"
gem "prawn-svg"
gem "victor"

# ===============================================================
#                    VIEW / UI ARCHITECTURE
# ===============================================================

gem "view_component"
gem "bullet"
gem "rails_semantic_logger"
gem "ruby-progressbar"
gem "amazing_print"

# ===============================================================
#                   DEVELOPMENT & TESTING
# ===============================================================

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "factory_bot_rails"
  gem "faker"
end

group :development do
  gem "yard"
  gem "annotate"
  gem "web-console"
  gem "rack-mini-profiler"
end

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