// =============================================================
// Toast Notification Controller
// =============================================================

// This controller manages the lifecycle of dynamic toast
// notifications within the application. It handles the
// creation, styling, and automatic dismissal of alerts
// to provide non-intrusive feedback to the user.

import {Controller} from "@hotwired/stimulus"

// This mapping assigns specific Lucide-style icon names
// to different message types, ensuring that notices,
// errors, and warnings are visually distinct.
const ICONS = {
    notice: "circle-check",
    success: "circle-check",
    alert: "circle-alert",
    error: "x",
    warning: "circle-alert",
    info: "info",
}

// This object defines the CSS color classes applied to
// icons based on the notification type, using standard
// semantic colors like success for success and danger for errors.
const COLORS = {
    notice: "text-success-600 p-1 bg-accent border border-border rounded-base",
    success: "text-success-600 p-1 bg-accent border border-border rounded-base",
    alert: "text-danger-600 p-1 bg-accent border border-border rounded-base",
    error: "text-danger-600 p-1 bg-accent border border-border rounded-base",
    warning: "text-alert-500 p-1 bg-accent border border-border rounded-base",
    info: "text-indigo-500 p-1 bg-accent border border-border rounded-base",
}

export default class extends Controller {

    // This configuration defines the reactive data for the
    // controller, including the array of messages to display
    // and the duration each toast remains visible on screen.
    static values = {
        messages: Array,
        duration: {type: Number, default: 4000},
    }

    // This method triggers automatically when the controller
    // connects, iterating through the provided message array
    // and staggering their appearance to prevent overlapping.
    connect() {
        this.messagesValue.forEach((msg, i) => {
            setTimeout(() => this.#show(msg.type, msg.text), i * 150)
        })
    }

    // This internal method handles the creation of the toast
    // element, applying Tailwind classes for positioning and
    // animation before injecting it into the document body.
    #show(type, text) {
        const toast = document.createElement("div")
        toast.className = [
            "flex items-center gap-2",
            "fixed top-6 left-1/2 -translate-x-1/2",
            "border border-border font-mono font-medium bg-white",
            "uppercase tracking-[0] rounded-base p-3 text-xs z-[99999]",
            "transition-all duration-300 opacity-0 -translate-y-2",
        ].join(" ")

        toast.innerHTML = `
            <span class="${COLORS[type] ?? "text-foreground"} shrink-0" data-toast-icon="${type}"></span>
            <span>${text}</span>
        `

        document.body.appendChild(toast)
        this.#injectIcon(toast.querySelector("[data-toast-icon]"), type)

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                toast.classList.remove("opacity-0", "-translate-y-2")
            })
        })

        setTimeout(() => this.#dismiss(toast), this.durationValue)
    }

    // This helper function initiates the exit animation for
    // a notification and ensures the DOM element is fully
    // removed once the transition effect has completed.
    #dismiss(toast) {
        if (!toast) return
        toast.classList.add("opacity-0", "-translate-y-2")
        toast.addEventListener("transitionend", () => toast.remove(), {once: true})
    }

    // This utility method locates the appropriate SVG icon
    // from a hidden symbol library on the page and clones
    // it into the toast for consistent vector rendering.
    #injectIcon(el, type) {
        const sprite = document.querySelector(`#toast-icons [data-icon="${type}"]`)
        if (sprite) {
            el.appendChild(sprite.cloneNode(true))
        }
    }
}