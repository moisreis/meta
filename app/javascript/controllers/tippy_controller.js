// =============================================================
// Tippy Controller
// =============================================================

// This controller manages the initialization and behavior of dynamic
// tooltips and popover menus across the application interface.
// It dynamically retrieves content from hidden elements to display
// rich HTML information when users interact with specific triggers.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    // This definition identifies the specific configuration type used
    // for the tooltip instance, allowing the controller to switch
    // between simple hints and interactive dropdown menus.
    static values = { type: String }

    // == connect
    //
    // @author Moisés Reis
    //
    // Configures and activates the Tippy instance on the host element
    // by selecting the appropriate layout and placement settings.
    // This method ensures that the tooltip content is correctly
    // fetched from the DOM and rendered with the specified theme.
    connect() {
        const base = {
            content: (reference) => {
                const selector = reference.dataset.tippyTarget
                if (!selector) return "Error loading content."
                const el = document.querySelector(selector)
                return el ? el.innerHTML : "Content not found."
            },
            allowHTML: true,
            theme: "meta",
            arrow: false,
        }

        const configs = {
            menu: {
                ...base,
                placement: "bottom",
                interactive: true,
                offset: [4, 0],
            },
            tooltip: {
                ...base,
                placement: "right",
                interactive: false,
                offset: [0, 4],
                appendTo: () => document.body,
            },
        }

        const config = configs[this.typeValue] ?? configs.tooltip
        this.tippy = tippy(this.element, config)
    }

    // == disconnect
    //
    // @author Moisés Reis
    //
    // Destroys the active Tippy instance to free up browser resources
    // and prevent orphaned tooltip elements from lingering in the DOM.
    // This cleanup ensures the application remains performant during
    // Turbo-driven page transitions and element removals.
    disconnect() {
        this.tippy?.[0]?.destroy()
    }
}