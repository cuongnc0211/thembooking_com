import { Controller } from "@hotwired/stimulus"

// Pricing page controller — billing toggle, early bird slot counter, FAQ accordion
export default class extends Controller {
  static targets = ["price", "originalPrice", "earlyBirdTag", "slots", "slotsBar", "faqAnswer", "faqIcon"]

  connect() {
    this.billing = "monthly"
    this._startSlotCounter()
  }

  disconnect() {
    if (this._slotTimer) clearInterval(this._slotTimer)
  }

  // ── Billing Toggle ────────────────────────────────────────────────────────

  setMonthly() {
    this.billing = "monthly"
    this._updatePrices()
    this._updateToggleUI()
  }

  setYearly() {
    this.billing = "yearly"
    this._updatePrices()
    this._updateToggleUI()
  }

  _updatePrices() {
    this.priceTargets.forEach(el => {
      el.textContent = el.dataset[this.billing] || el.dataset.monthly
    })
    // Show/hide original-price and early-bird tag on Pro card
    this.originalPriceTargets.forEach(el => {
      el.classList.toggle("hidden", false) // always show crossed-out original
    })
    this.earlyBirdTagTargets.forEach(el => {
      el.classList.toggle("hidden", false)
    })
  }

  _updateToggleUI() {
    const monthlyBtn = this.element.querySelector("[data-billing-monthly]")
    const yearlyBtn  = this.element.querySelector("[data-billing-yearly]")
    if (!monthlyBtn || !yearlyBtn) return

    const activeClass   = ["bg-white", "text-slate-900", "shadow-sm"]
    const inactiveClass = ["text-slate-400"]

    if (this.billing === "monthly") {
      monthlyBtn.classList.add(...activeClass)
      monthlyBtn.classList.remove(...inactiveClass)
      yearlyBtn.classList.remove(...activeClass)
      yearlyBtn.classList.add(...inactiveClass)
    } else {
      yearlyBtn.classList.add(...activeClass)
      yearlyBtn.classList.remove(...inactiveClass)
      monthlyBtn.classList.remove(...activeClass)
      monthlyBtn.classList.add(...inactiveClass)
    }
  }

  // ── Early Bird Slot Counter ───────────────────────────────────────────────

  _startSlotCounter() {
    let slots = 36
    const min = 28
    const totalSlots = 50

    const updateBar = () => {
      const taken = totalSlots - slots
      const pct = Math.round((taken / totalSlots) * 100)
      this.slotsBarTargets.forEach(el => {
        el.style.width = pct + "%"
      })
    }
    updateBar()

    this._slotTimer = setInterval(() => {
      if (slots <= min) return
      if (Math.random() < 0.15) {
        slots -= 1
        this.slotsTargets.forEach(el => { el.textContent = slots })
        updateBar()
      }
    }, 8000)
  }

  // ── FAQ Accordion ─────────────────────────────────────────────────────────

  toggleFaq(event) {
    const item = event.currentTarget.closest("[data-faq-item]")
    const isOpen = item.dataset.open === "true"

    // Close all
    this.element.querySelectorAll("[data-faq-item]").forEach(el => {
      el.dataset.open = "false"
      const answer = el.querySelector("[data-faq-answer]")
      const icon   = el.querySelector("[data-faq-icon]")
      if (answer) answer.style.maxHeight = "0"
      if (icon) icon.textContent = "+"
    })

    // Open clicked (unless it was already open)
    if (!isOpen) {
      item.dataset.open = "true"
      const answer = item.querySelector("[data-faq-answer]")
      const icon   = item.querySelector("[data-faq-icon]")
      if (answer) answer.style.maxHeight = answer.scrollHeight + "px"
      if (icon) icon.textContent = "×"
    }
  }
}
