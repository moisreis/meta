// =============================================================
// Currency Formatting Controller
// =============================================================

// This controller manages the real-time formatting of currency inputs.
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
        if (initial && !isNaN(parseFloat(initial))) {
            this.displayTarget.value = this.#toDisplay(parseFloat(initial))
        }
    }

    // This function listens to input changes, strips non-numeric
    // characters from the field, and updates the display and
    // hidden values to represent the correct currency amount.
    format(event) {
        const digits = event.target.value.replace(/\D/g, "")

        if (!digits) {
            this.displayTarget.value = ""
            this.hiddenTarget.value = ""
            return
        }

        const cents = parseInt(digits, 10)
        const float = cents / 100

        this.displayTarget.value = this.#toDisplay(float)
        this.hiddenTarget.value = float.toFixed(2)
    }

    // This internal helper method converts a numeric value into a
    // string formatted according to the Brazilian Portuguese locale,
    // ensuring the standard currency presentation for the user.
    #toDisplay(float) {
        return float.toLocaleString("pt-BR", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
        })
    }
}