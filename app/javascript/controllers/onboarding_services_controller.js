import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "serviceRow"]

  connect() {
    this.nextIndex = Date.now()
  }

  addService() {
    const template = this.templateTarget.innerHTML
    const index = this.nextIndex++
    const newService = template.replace(/NEW_RECORD/g, index)
    this.containerTarget.insertAdjacentHTML("beforeend", newService)
  }

  removeService(event) {
    const row = event.target.closest("[data-onboarding-services-target='serviceRow']")
    const destroyInput = row.querySelector("input[name*='_destroy']")

    if (destroyInput) {
      // Mark for deletion if it's a persisted record
      destroyInput.value = "1"
      row.style.display = "none"
    } else {
      // Just remove if it's a new record
      row.remove()
    }
  }
}