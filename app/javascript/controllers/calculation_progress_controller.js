// =============================================================
// Calculation Progress Controller
// =============================================================

// This controller manages the visual progress of background performance
// calculations. It intercepts form submissions to display a real-time
// loading overlay and polls a specific endpoint to update a progress
// bar until the process is finished.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    // These values define the configuration for the polling mechanism,
    // identifying the specific URL to track and the frequency of the
    // updates to ensure the user sees smooth progress.
    static values = {
        pollUrl: String,
        pollInterval: { type: Number, default: 600 }
    }

    // This method initializes the internal tracking variables when the
    // controller starts. It sets up the base state for the overlay
    // and the timer used to fetch progress updates from the server.
    connect() {
        this._overlay   = null
        this._pollTimer = null
    }

    // This function handles the form submission by preventing the default
    // page reload, launching the progress overlay, and sending the data
    // via an asynchronous request while monitoring the backend status.
    async submit(event) {
        event.preventDefault()

        const form = event.currentTarget
        this._showOverlay()
        this._startPolling()

        try {
            const response = await fetch(form.action, {
                method: (form.getAttribute("method") || "POST").toUpperCase(),
                headers: { "X-CSRF-Token": this._csrf(), "Accept": "text/html" },
                body:    new FormData(form)
            })

            this._setProgress(100, "Concluído!")
            await this._sleep(600)

            window.location.href = response.url || window.location.href
        } catch (err) {
            this._stopPolling()
            this._hideOverlay()
            console.error("[calculation_progress] fetch error:", err)
            form.submit()
        }
    }

    // This internal method creates and injects the progress overlay into
    // the document. It ensures the visual elements are correctly
    // rendered and animated to provide clear feedback to the user.
    _showOverlay() {
        if (this._overlay) return

        this._overlay = document.createElement("div")
        this._overlay.id = "calc-progress-overlay"
        this._overlay.innerHTML = this._overlayHTML()
        document.body.appendChild(this._overlay)

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                this._overlay?.classList.add("calc-overlay--visible")
            })
        })
    }

    // This helper removes the progress overlay from the screen once the
    // task is complete. It uses a transition effect to fade out the
    // element before permanently removing it from the page structure.
    _hideOverlay() {
        if (!this._overlay) return
        this._overlay.classList.remove("calc-overlay--visible")
        this._overlay.addEventListener("transitionend", () => this._overlay?.remove(), { once: true })
        this._overlay = null
    }

    // This function updates the visual state of the progress bar and
    // its labels. It maps the numerical percentage and the current
    // step description onto the corresponding HTML elements.
    _setProgress(percent, label) {
        if (!this._overlay) return
        const bar   = this._overlay.querySelector(".calc-bar__fill")
        const pct   = this._overlay.querySelector(".calc-pct")
        const step  = this._overlay.querySelector(".calc-step")

        if (bar)  bar.style.width   = `${Math.min(percent, 100)}%`
        if (pct)  pct.textContent   = `${Math.round(percent)}%`
        if (step && label) step.textContent = label
    }

    // This internal logic establishes a recurring timer that fetches
    // the latest status from the server. It updates the progress bar
    // automatically and stops itself once the "done" state is reached.
    _startPolling() {
        if (!this.pollUrlValue) return

        this._pollTimer = setInterval(async () => {
            try {
                const res  = await fetch(this.pollUrlValue, {
                    headers: { "Accept": "application/json", "X-CSRF-Token": this._csrf() }
                })
                const data = await res.json()

                this._setProgress(data.percent, data.step)

                if (data.done) this._stopPolling()
            } catch (_) {
                // Polling errors are ignored to avoid interrupting the main process
            }
        }, this.pollIntervalValue)
    }

    // This function clears the active polling interval, effectively
    // stopping any further network requests for progress updates
    // when the calculation is finished or an error occurs.
    _stopPolling() {
        clearInterval(this._pollTimer)
        this._pollTimer = null
    }

    // This utility retrieves the security token required for Rails
    // requests. It ensures that background communication with the
    // server remains authenticated and secure.
    _csrf() {
        return document.querySelector("meta[name='csrf-token']")?.content ?? ""
    }

    // This simple helper pauses the execution for a specific amount
    // of time. It is used to ensure visual transitions complete
    // naturally before the user is redirected to a new page.
    _sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms))
    }

    // This internal method returns the raw HTML structure for the
    // progress overlay. It contains the layout for the spinner,
    // labels, and the dynamic progress bar container.
    _overlayHTML() {
        return `
    <div class="fixed inset-0 bg-body/50 backdrop-blur-sm z-[9998]"></div>
    <div class="fixed inset-0 z-[9999] flex items-center justify-center pointer-events-none">
      <div class="bg-white rounded-base border border-border p-16 w-[520px] max-w-[90vw] flex flex-col items-center gap-3 pointer-events-auto">
            <svg xmlns="http://www.w3.org/2000/svg" 
                         style="animation: spin 1s linear infinite; margin-bottom: calc(var(--spacing)*8)" viewBox="0 0 24 24" width="24" height="24" color="currentColor" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round">
                <path d="M12 3V6" />
                <path d="M12 18V21" />
                <path d="M21 12L18 12" />
                <path d="M6 12L3 12" />
                <path d="M18.3635 5.63672L16.2422 7.75804" />
                <path d="M7.75804 16.2422L5.63672 18.3635" />
                <path d="M18.3635 18.3635L16.2422 16.2422" />
                <path d="M7.75804 7.75804L5.63672 5.63672" />
            </svg>
        <p class="text-base font-semibold uppercase font-mono uppercase tracking-0 text-body m-0">Calculando Performance</p>
        <p class="calc-step font-mono text-sm text-muted uppercase tracking-0 m-0 text-center min-h-5">Iniciando</p>
        <div class="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden mt-2">
          <div class="calc-bar__fill h-full rounded-base transition-all duration-300 ease-out"
               style="width: 0%; background: var(--color-primary-950)"></div>
        </div>
        <p class="calc-pct text-sm font-normal font-mono m-0" style="color: var(--color-body)">0%</p>
      </div>
    </div>
    <style>
      @keyframes spin { to { transform: rotate(360deg); } }
      #calc-progress-overlay { opacity: 0; transition: opacity 0.25s ease; }
      #calc-progress-overlay.calc-overlay--visible { opacity: 1; }
    </style>
  `
    }
}