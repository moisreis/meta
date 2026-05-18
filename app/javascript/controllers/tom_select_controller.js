import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { rich: { type: Boolean, default: false } }

  connect() {
    this.tomSelect = new TomSelect(this.element, {
      create: false,
      allowEmptyOption: true,
      maxItems: 1,
      sortField: { field: "text", direction: "asc" },
      placeholder: "Escolha uma opção",
      searchField: this.richValue ? ["text", "subtitle"] : ["text"],
      plugins: { dropdown_input: {} },
      render: this.richValue ? this.#richRender() : this.#defaultRender()
    })
  }

  disconnect() {
    this.tomSelect?.destroy()
  }

  // -- Private ---------------------------------------------------------------

  #defaultRender() {
    return {
      option: (data, escape) =>
        `<div class="option">${escape(data.text)}</div>`
    }
  }

  #richRender() {
    return {
      option: (data, escape) => `
        <div class="flex flex-col gap-0.5 py-0.5">
          <span>
            ${escape(data.text)}
          </span>
          <span class="block font-mono text-2xs text-muted">
            ${escape(data.subtitle ?? '')}
          </span>
        </div>`,
      item: (data, escape) =>
        `<div>${escape(data.text)}</div>`
    }
  }
}