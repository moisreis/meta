// =============================================================
// CNPJ Formatting Controller
// =============================================================

// This controller manages the real-time formatting of CNPJ inputs.
// It synchronizes a user-friendly display field with a raw hidden
// field to ensure data integrity during form submissions.

import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    // This definition specifies the HTML elements that this controller
    // interacts with, allowing it to manipulate both the formatted
    // display field and the raw data hidden field.
    static targets = ["display", "hidden"]

    // This method runs automatically when the controller is attached
    // to an element, ensuring any existing data in the hidden field
    // is correctly formatted for the user to see upon page load.
    connect() {
        const initial = this.hiddenTarget.value
        if (initial) {
            this.displayTarget.value = this.#toDisplay(initial)
        }
    }

    // This function listens to input changes, strips non-numeric
    // characters from the field, and updates the display and
    // hidden values to represent the correct CNPJ format.
    format(event) {
        const digits = event.target.value.replace(/\D/g, "").slice(0, 14)

        if (!digits) {
            this.displayTarget.value = ""
            this.hiddenTarget.value = ""
            return
        }

        this.displayTarget.value = this.#toDisplay(digits)
        this.hiddenTarget.value = digits
    }

    // This internal helper method converts a raw digit string into a
    // CNPJ-formatted string following the Brazilian standard mask,
    // ensuring the correct presentation for the user.
    #toDisplay(digits) {
        return digits
            .replace(/^(\d{2})(\d)/, "$1.$2")
            .replace(/^(\d{2})\.(\d{3})(\d)/, "$1.$2.$3")
            .replace(/\.(\d{3})(\d)/, ".$1/$2")
            .replace(/(\d{4})(\d)/, "$1-$2")
    }
}