import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "serviceRow"]

  addService() {
    const template = this.templateTarget.innerHTML
    const index = this.serviceRowTargets.length
    const newService = template.replace(/INDEX_PLACEHOLDER/g, index)
    this.containerTarget.insertAdjacentHTML("beforeend", newService)
  }

  removeService(event) {
    const row = event.target.closest("[data-onboarding-services-target='serviceRow']")
    row.remove()
  }
}