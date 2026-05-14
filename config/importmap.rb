# Defines JavaScript module import mappings for the Rails application using Importmap.
#
# This file maps frontend dependencies to their corresponding asset paths,
# enabling module-based JavaScript without a bundler.
#
# @author Moisés Reis

# ============================================================================
# CORE APPLICATION
# ============================================================================

# Main application entry point.
pin "application"

# ============================================================================
# VISUALIZATION LIBRARIES
# ============================================================================

# Chartkick wrapper for data visualization.
pin "chartkick", to: "chartkick.js"

# Chart.js bundled dependency required by Chartkick.
pin "Chart.bundle", to: "Chart.bundle.js"

# ============================================================================
# HOTWIRE FRAMEWORK
# ============================================================================

# Turbo for SPA-like navigation.
pin "@hotwired/turbo-rails", to: "turbo.min.js"

# Stimulus core framework.
pin "@hotwired/stimulus", to: "stimulus.min.js"

# Lazy-loading helper for Stimulus controllers.
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# ============================================================================
# STIMULUS CONTROLLERS
# ============================================================================

# Auto-load all Stimulus controllers from the controllers directory.
pin_all_from "app/javascript/controllers", under: "controllers"
