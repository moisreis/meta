# Defines JavaScript module import mappings for the Rails application using Importmap.
#
# This file maps frontend dependencies to their corresponding asset paths,
# enabling module-based JavaScript without a bundler.
#
# TABLE OF CONTENTS:
#
# 1. Core Application
# 2. Visualization Libraries
# 3. Hotwire Framework
# 4. Stimulus Controllers
#
# @author Moisés Reis

# =============================================================
#                     1. CORE APPLICATION
# =============================================================

# Main application entry point.
pin "application"

# =============================================================
#                  2. VISUALIZATION LIBRARIES
# =============================================================

# Chartkick wrapper for data visualization.
pin "chartkick", to: "chartkick.js"

# Chart.js bundled dependency required by Chartkick.
pin "Chart.bundle", to: "Chart.bundle.js"

# =============================================================
#                     3. HOTWIRE FRAMEWORK
# =============================================================

# Turbo for SPA-like navigation.
pin "@hotwired/turbo-rails", to: "turbo.min.js"

# Stimulus core framework.
pin "@hotwired/stimulus", to: "stimulus.min.js"

# Lazy-loading helper for Stimulus controllers.
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# =============================================================
#                  4. STIMULUS CONTROLLERS
# =============================================================

# Auto-load all Stimulus controllers from the controllers directory.
pin_all_from "app/javascript/controllers", under: "controllers"
