// =============================================================
// Datepicker Controller
// =============================================================

// This controller initializes and manages a localized date picker
// interface. It transforms standard input fields into interactive
// calendars that follow specific regional formatting rules.

import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    // == connect
    // @author Moisés Reis
    //
    // Initializes the Flatpickr instance on the target element with
    // custom Brazilian Portuguese localization and visual settings.
    // This ensures users see a friendly date format while the system
    // receives a standard ISO format for data processing.
    connect() {
        this.flatpickr = flatpickr(this.element, {
            dateFormat: "Y-m-d",
            altInput: true,
            altFormat: "d/m/Y",
            allowInput: false,
            disableMobile: true,
            monthSelectorType: "static",
            yearSelectorType: "static",
            prevArrow: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg>`,
            nextArrow: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg>`,
            locale: {
                firstDayOfWeek: 1,
                weekdays: {
                    shorthand: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"],
                    longhand: ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"]
                },
                months: {
                    shorthand: ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"],
                    longhand: ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
                }
            }
        })
    }

    // == disconnect
    // @author Moisés Reis
    //
    // Safely destroys the Flatpickr instance when the controller
    // is removed from the DOM.
    // This prevents memory leaks and ensures that leftover calendar
    // elements do not remain in the browser's memory.
    disconnect() {
        this.flatpickr?.destroy()
    }
}