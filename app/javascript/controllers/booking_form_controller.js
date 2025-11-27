import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "serviceCheckbox",
    "summary",
    "totalDuration",
    "totalPrice",
    "dateTimeSection",
    "dateInput",
    "timeSlotsContainer",
    "loadingSpinner",
    "timeSlots",
    "noSlotsMessage",
    "scheduledAtInput",
    "customerSection",
    "submitButton"
  ]

  static values = {
    businessSlug: String
  }

  connect() {
    this.selectedTimeSlot = null
    this.updateSelection()
  }

  // Called when service checkboxes are changed
  updateSelection() {
    const selectedServices = this.getSelectedServices()

    if (selectedServices.length > 0) {
      // Calculate totals
      const totalDuration = selectedServices.reduce((sum, service) => sum + service.duration, 0)
      const totalPrice = selectedServices.reduce((sum, service) => sum + service.price, 0)

      // Update display
      this.totalDurationTarget.textContent = `${totalDuration} min`
      this.totalPriceTarget.textContent = this.formatCurrency(totalPrice)

      // Show summary and date/time section
      this.summaryTarget.classList.remove("hidden")
      this.dateTimeSectionTarget.classList.remove("hidden")

      // If date is already selected, re-fetch availability
      if (this.dateInputTarget.value) {
        this.fetchAvailability()
      }
    } else {
      // Hide summary and date/time section
      this.summaryTarget.classList.add("hidden")
      this.dateTimeSectionTarget.classList.add("hidden")
      this.timeSlotsContainerTarget.classList.add("hidden")
    }

    this.updateSubmitButton()
  }

  // Fetch available time slots from server
  async fetchAvailability() {
    const selectedServices = this.getSelectedServices()
    const date = this.dateInputTarget.value

    if (selectedServices.length === 0 || !date) {
      return
    }

    // Show time slots container and loading spinner
    this.timeSlotsContainerTarget.classList.remove("hidden")
    this.loadingSpinnerTarget.classList.remove("hidden")
    this.timeSlotsTarget.innerHTML = ""
    this.noSlotsMessageTarget.classList.add("hidden")

    try {
      const serviceIds = selectedServices.map(s => s.id)
      const params = new URLSearchParams({
        date: date,
        ...Object.fromEntries(serviceIds.map(id => [`service_ids[]`, id]))
      })

      const response = await fetch(`/${this.businessSlugValue}/availability?${params}`)
      const data = await response.json()

      // Hide loading spinner
      this.loadingSpinnerTarget.classList.add("hidden")

      if (data.available_slots && data.available_slots.length > 0) {
        this.renderTimeSlots(data.available_slots)
      } else {
        this.noSlotsMessageTarget.classList.remove("hidden")
      }
    } catch (error) {
      console.error("Error fetching availability:", error)
      this.loadingSpinnerTarget.classList.add("hidden")
      this.noSlotsMessageTarget.classList.remove("hidden")
    }
  }

  // Render time slot buttons
  renderTimeSlots(slots) {
    this.timeSlotsTarget.innerHTML = ""
    this.selectedTimeSlot = null

    slots.forEach(slot => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "time-slot-btn px-4 py-2 rounded-lg border-2 border-slate-200 text-sm font-medium text-slate-700 hover:border-primary-300 hover:bg-primary-50 hover:text-primary-700 transition-all focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2"
      button.textContent = this.formatTime(slot)
      button.dataset.time = slot
      button.addEventListener("click", () => this.selectTimeSlot(button, slot))

      this.timeSlotsTarget.appendChild(button)
    })
  }

  // Handle time slot selection
  selectTimeSlot(button, time) {
    // Remove selected state from all buttons
    this.timeSlotsTarget.querySelectorAll(".time-slot-btn").forEach(btn => {
      btn.classList.remove("border-primary-600", "bg-primary-100", "text-primary-900")
      btn.classList.add("border-slate-200", "text-slate-700")
    })

    // Add selected state to clicked button
    button.classList.remove("border-slate-200", "text-slate-700")
    button.classList.add("border-primary-600", "bg-primary-100", "text-primary-900")

    // Store selected time and update hidden field
    this.selectedTimeSlot = time
    this.scheduledAtInputTarget.value = time

    // Show customer section and update submit button
    this.customerSectionTarget.classList.remove("hidden")
    this.updateSubmitButton()
  }

  // Update submit button state
  updateSubmitButton() {
    const selectedServices = this.getSelectedServices()
    const hasServices = selectedServices.length > 0
    const hasDate = this.dateInputTarget.value !== ""
    const hasTimeSlot = this.selectedTimeSlot !== null

    this.submitButtonTarget.disabled = !(hasServices && hasDate && hasTimeSlot)
  }

  // Helper: Get selected services with their data
  getSelectedServices() {
    return this.serviceCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => ({
        id: checkbox.value,
        duration: parseInt(checkbox.dataset.duration),
        price: parseInt(checkbox.dataset.price)
      }))
  }

  // Helper: Format currency (Vietnamese Dong)
  formatCurrency(cents) {
    const amount = cents / 100
    return new Intl.NumberFormat("vi-VN", {
      style: "currency",
      currency: "VND"
    }).format(amount)
  }

  // Helper: Format time string
  formatTime(isoString) {
    const date = new Date(isoString)
    return date.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
      hour12: true
    })
  }
}
