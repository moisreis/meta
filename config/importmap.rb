# === importmap.rb
#
# Description:: Manages the import map configuration for the application.
#               It maps JavaScript module names to their corresponding files
#               so the browser can resolve dependencies correctly.
#
# Usage:: *What* - Defines the manifest of JavaScript packages available.
#         *How* - Uses the pin command to map import names to library files.
#         *Why* - Allows the application to use modern JavaScript imports
#         without needing a complex bundler like Webpack.
#
# Attributes:: - *pin* - Maps a module name to a specific file or path.
#              - *pin_all_from* - Registers all modules within a directory.
#
# View:: - None
#
# Notes:: References to internal scripts or gems like +Turbo+ or +Stimulus+
#         are handled via this map to ensure they load properly in the browser.


# =============================================================
# Package Definitions
# =============================================================

# This directive maps the core application entry point to its file.
# It serves as the primary script for site-wide initialization.
pin "application"

# This maps the Chartkick library to its source file.
# It makes the charting interface available for the application.
pin "chartkick", to: "chartkick.js"

# This maps the Chart.bundle library to its source file.
# It provides the rendering engine required by Chartkick.
pin "Chart.bundle", to: "Chart.bundle.js"

# This maps the Turbo library to the minified source file.
# It enables fast navigation and dynamic page updates.
pin "@hotwired/turbo-rails", to: "turbo.min.js"

# This maps the Stimulus framework to the minified source file.
# It provides the base for modular JavaScript components.
pin "@hotwired/stimulus", to: "stimulus.min.js"

# This maps the Stimulus loading utility to its source file.
# It automates the discovery and registration of controllers.
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# This directive imports all JavaScript files in the controllers folder.
# It makes these local controllers available under the controllers namespace.
pin_all_from "app/javascript/controllers", under: "controllers"