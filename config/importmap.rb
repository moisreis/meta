# frozen_string_literal: true

# config/importmap.rb
#
# Defines JavaScript module resolution rules for the Rails Importmap system.
#
# Maps logical module identifiers to asset paths, enabling native ES module
# loading in the browser without a build step.
#
# @author  Moisés Reis


# == Application Entry ======================================================

pin "application"


# == Visualization Libraries ================================================

# -- Chartkick --------------------------------------------------------------

pin "chartkick", to: "chartkick.js"

pin "Chart.bundle", to: "Chart.bundle.js"


# == Hotwire Stack ==========================================================

# -- Turbo ------------------------------------------------------------------

pin "@hotwired/turbo-rails", to: "turbo.min.js"

# -- Stimulus ---------------------------------------------------------------

pin "@hotwired/stimulus", to: "stimulus.min.js"

pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"


# == Application Controllers ================================================

# Auto-registers all Stimulus controllers under the given directory.
pin_all_from "app/javascript/controllers", under: "controllers"