# frozen_string_literal: true

# Defines JavaScript module resolution rules for the Rails
# Importmap system.
#
# This configuration maps logical module identifiers to asset
# paths, enabling native ES module loading in the browser
# without a build step.
#
# @author Moisés Reis

# =============================================================
#                        APPLICATION ENTRY
# =============================================================

# Main application JavaScript entrypoint.
#
# @return [void]
pin "application"

# =============================================================
#                      VISUALIZATION LIBRARIES
# =============================================================

# Chart rendering library for data visualization.
#
# @return [void]
pin "chartkick", to: "chartkick.js"

# Chart.js bundle used as the underlying rendering engine.
#
# @return [void]
pin "Chart.bundle", to: "Chart.bundle.js"

# =============================================================
#                        HOTWIRE STACK
# =============================================================

# Turbo Rails integration for SPA-like navigation.
#
# @return [void]
pin "@hotwired/turbo-rails", to: "turbo.min.js"

# Stimulus JavaScript framework for lightweight interactivity.
#
# @return [void]
pin "@hotwired/stimulus", to: "stimulus.min.js"

# Stimulus loading helper for automatic controller discovery.
#
# @return [void]
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# =============================================================
#                    APPLICATION CONTROLLERS
# =============================================================

# Auto-registers all Stimulus controllers in the specified directory.
#
# @return [void]
pin_all_from "app/javascript/controllers", under: "controllers"