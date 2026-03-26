import { Controller } from "@hotwired/stimulus"

// Handles inline category quick-create on the service form.
// Submits the new category name via fetch (JSON), then appends the new option
// to the category <select> and selects it automatically.
export default class extends Controller {
  static targets = ["input", "select", "spinner"]
  static values = { url: String }

  async create(event) {
    event.preventDefault()
    const name = this.inputTarget.value.trim()
    if (!name) return

    this.spinnerTarget.classList.remove("hidden")

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({ service_category: { name } })
      })

      if (response.ok) {
        const data = await response.json()
        const option = new Option(data.name, data.id, true, true)
        this.selectTarget.add(option)
        this.inputTarget.value = ""
      } else {
        const err = await response.json()
        alert(err.errors?.join(", ") || "Failed to create category")
      }
    } catch {
      alert("Network error. Please try again.")
    } finally {
      this.spinnerTarget.classList.add("hidden")
    }
  }
}
