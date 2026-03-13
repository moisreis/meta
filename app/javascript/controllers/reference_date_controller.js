// =============================================================
// Reference Date Sync Controller
// =============================================================

// This controller synchronizes a selected reference date across
// multiple action forms. It ensures that viewing data, running
// performance calculations, and generating reports all use the
// same date value by updating hidden fields before submission.

import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    // This definition identifies the date input wrapper and the
    // various forms and hidden fields used for viewing data,
    // calculating monthly performance, and generating PDF reports.
    static targets = [
        "inputWrapper",
        "viewForm", "viewDate",
        "calcForm", "calcMonth",
        "reportForm", "reportDay", "reportMonth", "reportYear"
    ]

    // This helper property retrieves the date value in ISO format
    // (YYYY-MM-DD) from the input field, checking both standard
    // value attributes and custom data attributes from datepickers.
    get dateValue() {
        const input = this.inputWrapperTarget.querySelector("input")
        if (!input) return null

        return input.dataset.isoValue || input.value || null
    }

    // This method decomposes an ISO date string into its numeric
    // year, month, and day components, allowing the controller to
    // format the date specifically for different backend requirements.
    parseDate(iso) {
        if (!iso) return null
        const [year, month, day] = iso.split("-").map(Number)
        if (!year || !month || !day) return null
        return {year, month, day}
    }

    // This action updates the view form's hidden date field with the
    // currently selected date and submits the form to refresh the
    // page with data corresponding to that specific reference day.
    view() {
        const iso = this.dateValue
        if (!this.#guardDate(iso)) return

        this.viewDateTarget.value = iso
        this.viewFormTarget.submit()
    }

    // This action formats the selected date into a "YYYY-MM" string
    // required by the calculation engine, updates the hidden month
    // field, and triggers the performance calculation process.
    calculate() {
        const iso = this.dateValue
        if (!this.#guardDate(iso)) return

        const parsed = this.parseDate(iso)
        if (!parsed) return

        const month = `${parsed.year}-${String(parsed.month).padStart(2, "0")}`
        this.calcMonthTarget.value = month
        this.calcFormTarget.submit()
    }

    // This action breaks the date into separate day, month, and year
    // hidden fields for the report generator and uses a request
    // submission to ensure the download triggers correctly.
    report() {
        const iso = this.dateValue
        if (!this.#guardDate(iso)) return

        const parsed = this.parseDate(iso)
        if (!parsed) return

        this.reportDayTarget.value = parsed.day
        this.reportMonthTarget.value = parsed.month
        this.reportYearTarget.value = parsed.year

        this.reportFormTarget.requestSubmit()
    }

    // This internal private method validates that a date has been
    // selected before allowing any form submission, providing an
    // alert to the user if the date field is currently empty.
    #guardDate(iso) {
        if (iso) return true
        alert("Selecione uma data antes de continuar.")
        return false
    }
}