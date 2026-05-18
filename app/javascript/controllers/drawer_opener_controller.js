// app/javascript/controllers/sidebar_opener_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { name: String }

  open() {
    document.dispatchEvent(new CustomEvent(`drawer:open:${this.nameValue}`))
  }
}