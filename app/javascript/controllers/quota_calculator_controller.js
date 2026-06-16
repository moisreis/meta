import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["financialValue", "numberOfQuotas", "quotaValue"]

  calculate() {
    const value  = parseFloat(this.financialValueTarget.value)
    const quotas = parseFloat(this.numberOfQuotasTarget.value)

    if (value > 0 && quotas > 0) {
      this.quotaValueTarget.value = (value / quotas).toFixed(6)
    }
  }
}