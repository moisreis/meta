// =============================================================
// Application Dependencies
// =============================================================

// This section defines the core JavaScript libraries and modules
// required to power the frontend features of the application.
// It ensures that charting capabilities and interactive navigation
// components are loaded and ready for use upon page initialization.

// This statement imports the Chartkick library into the application.
// It provides the high-level interface needed to render interactive
// data visualizations directly from your Ruby backend data.
import "chartkick"

// This statement includes the Chart.bundle dependency for the project.
// It provides the essential rendering engine and configuration files
// required to support the graphical charts displayed on the page.
import "Chart.bundle"

// This statement registers the Hotwired Turbo library for this application.
// It enables seamless navigation by loading partial page content
// dynamically, which significantly improves the responsiveness of the UI.
import "@hotwired/turbo-rails"

// This statement imports the local directory containing stimulus controllers.
// It connects the application's modular frontend logic to the HTML
// elements, allowing for dynamic interactions across the interface.
import "controllers"