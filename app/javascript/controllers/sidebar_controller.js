import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["aside", "container"]

    connect() {
        const collapsed = localStorage.getItem("sidebar-collapsed") === "true"
        if (collapsed) this.applyState(true)
    }

    toggle() {
        const isCollapsed = this.asideTarget.dataset.collapsed === "true"
        this.applyState(!isCollapsed)
        localStorage.setItem("sidebar-collapsed", String(!isCollapsed))
    }

    applyState(collapsed) {
        this.asideTarget.dataset.collapsed = String(collapsed)
        this.containerTarget.dataset.sidebarCollapsed = String(collapsed)
    }
}