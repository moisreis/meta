// =============================================================
// Stimulus Application Configuration
// =============================================================

// This module initializes the Stimulus framework for the browser.
// It sets up the global application instance and exports it so
// that it can be easily accessed by other parts of the system.

import { Application } from "@hotwired/stimulus"

// This line starts the Stimulus application, enabling the 
// framework to manage controllers and lifecycle events.
const application = Application.start()

// This line disables debug mode to keep the console clean
// in the production environment while the application runs.
application.debug = false

// This line assigns the application instance to the window object,
// making it globally accessible for testing or debugging in the browser.
window.Stimulus = application

export { application }