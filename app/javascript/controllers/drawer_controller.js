// app/javascript/controllers/drawer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]
  static values  = { name: String }

  initialize() {
    this._onOpen   = this.open.bind(this)
    this._onEscape = this._handleEscape.bind(this)
  }

  connect() {
    document.addEventListener(`drawer:open:${this.nameValue}`, this._onOpen)
    document.addEventListener("keydown", this._onEscape)
  }

  disconnect() {
    document.removeEventListener(`drawer:open:${this.nameValue}`, this._onOpen)
    document.removeEventListener("keydown", this._onEscape)
  }

  open() {
    this.panelTarget.classList.remove("opacity-0", "pointer-events-none")
    this.panelTarget.classList.add("opacity-100")
    this.overlayTarget.classList.remove("hidden")
  }

  close() {
    this.panelTarget.classList.add("opacity-0", "pointer-events-none")
    this.panelTarget.classList.remove("opacity-100")
    this.overlayTarget.classList.add("hidden")
  }

  _handleEscape({ key }) {
    if (key === "Escape") this.close()
  }
}