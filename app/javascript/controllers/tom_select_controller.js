// =============================================================
// Tom Select Controller
// =============================================================

// This controller initializes an enhanced dropdown interface that
// replaces standard select elements with searchable inputs.
// It improves the user experience by providing a custom layout
// for options and a simplified search mechanism.

import {Controller} from "@hotwired/stimulus"

export default class extends Controller {

    // == connect
    //
    // @author Moisés Reis
    //
    // Instantiates the TomSelect library on the associated element
    // with custom search, sorting, and rendering configurations.
    // This setup ensures that large lists are easy to navigate
    // through a responsive and stylized dropdown menu.
    connect() {
        this.tomSelect = new TomSelect(this.element, {
            create: false,
            allowEmptyOption: true,
            maxItems: 1,
            sortField: {field: "text", direction: "asc"},
            placeholder: "Escolha uma opção",
            searchField: ["text"],
            plugins: {dropdown_input: {}},
            render: {
                option: (data, escape) => `<div class="option">${escape(data.text)}</div>`
            }
        })
    }

    // == disconnect
    //
    // @author Moisés Reis
    //
    // Removes the TomSelect instance and restores the original
    // HTML select element when the controller is disconnected.
    // This cleanup process is essential for maintaining application
    // performance and preventing visual artifacts in the interface.
    disconnect() {
        this.tomSelect?.destroy()
    }
}