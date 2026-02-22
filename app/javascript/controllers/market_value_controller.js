// app/javascript/controllers/market_value_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["date", "value", "quota"]
    static values = { fundInvestmentId: Number }

    async fetch() {
        const date = this.dateTarget.value
        if (!date) return

        const res = await fetch(
            `/fund_investments/${this.fundInvestmentIdValue}/market_value_on?date=${date}`
        )
        const data = await res.json()

        this.valueTarget.textContent = data.value
            ? `R$ ${Number(data.value).toLocaleString('pt-BR', { minimumFractionDigits: 2 })}`
            : "Sem dados"

        if (this.hasQuotaTarget) {
            this.quotaTarget.textContent = data.quota
                ? Number(data.quota).toLocaleString('pt-BR', { minimumFractionDigits: 6 })
                : "-"
        }
    }
}