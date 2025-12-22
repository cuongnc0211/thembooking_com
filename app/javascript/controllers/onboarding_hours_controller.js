import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "weekdaysCheckbox",
    "weekdaysUnified",
    "weekdaysExpanded",
    "weekdayExpandButton",
    "saturdayTimes",
    "sundayTimes"
  ]

  static values = {
    expanded: { type: Boolean, default: false }
  }

  connect() {
    // Initialize state based on existing data
    this.checkIfShouldStartExpanded()
  }

  checkIfShouldStartExpanded() {
    // If user is editing and has different hours per weekday, start expanded
    const monday = document.querySelector('[name="operating_hours[monday][open]"]')
    const tuesday = document.querySelector('[name="operating_hours[tuesday][open]"]')

    if (monday && tuesday && monday.value !== tuesday.value) {
      this.expandedValue = true
      this.showExpandedState()
    }
  }

  toggleWeekdayExpansion(event) {
    if (event) event.preventDefault()

    this.expandedValue = !this.expandedValue

    if (this.expandedValue) {
      this.showExpandedState()
    } else {
      this.showCollapsedState()
    }
  }

  showExpandedState() {
    // Hide unified, show individual days
    this.weekdaysUnifiedTarget.classList.add('hidden')
    this.weekdaysExpandedTarget.classList.remove('hidden')

    // Update button text and icon
    this.weekdayExpandButtonTarget.innerHTML = `
      <span>Use same hours for all weekdays</span>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"/>
      </svg>
    `

    // Copy unified hours to all individual days
    this.copyUnifiedToIndividual()
  }

  showCollapsedState() {
    // Show unified, hide individual days
    this.weekdaysUnifiedTarget.classList.remove('hidden')
    this.weekdaysExpandedTarget.classList.add('hidden')

    // Update button text and icon
    this.weekdayExpandButtonTarget.innerHTML = `
      <span>Customize individual days</span>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
      </svg>
    `

    // Copy Monday's hours back to unified (or average, or just keep)
    this.copyIndividualToUnified()
  }

  copyUnifiedToIndividual() {
    const unifiedOpen = this.weekdaysUnifiedTarget.querySelector('[name*="[open]"]').value
    const unifiedClose = this.weekdaysUnifiedTarget.querySelector('[name*="[close]"]').value

    ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'].forEach(day => {
      const dayOpen = document.querySelector(`[name="operating_hours[${day}][open]"]`)
      const dayClose = document.querySelector(`[name="operating_hours[${day}][close]"]`)

      if (dayOpen && unifiedOpen) dayOpen.value = unifiedOpen
      if (dayClose && unifiedClose) dayClose.value = unifiedClose
    })
  }

  copyIndividualToUnified() {
    // Use Monday's hours as the unified hours
    const mondayOpen = document.querySelector('[name="operating_hours[monday][open]"]')
    const mondayClose = document.querySelector('[name="operating_hours[monday][close]"]')

    if (mondayOpen && mondayOpen.value) {
      this.weekdaysUnifiedTarget.querySelector('[name*="[open]"]').value = mondayOpen.value
      this.weekdaysUnifiedTarget.querySelector('[name*="[close]"]').value = mondayClose.value
    }
  }

  toggleDay(event) {
    const target = event.target.dataset.target

    // Handle weekdays checkbox - toggle both unified and expanded fields
    if (target === "weekdays") {
      const unifiedInputs = this.weekdaysUnifiedTarget.querySelectorAll("input")
      unifiedInputs.forEach(input => {
        input.disabled = !event.target.checked
      })

      const expandedInputs = this.weekdaysExpandedTarget.querySelectorAll("input")
      expandedInputs.forEach(input => {
        input.disabled = !event.target.checked
      })
    } else {
      // Handle Saturday and Sunday
      const timesTarget = this[`${target}TimesTarget`]
      const inputs = timesTarget.querySelectorAll("input")

      inputs.forEach(input => {
        input.disabled = !event.target.checked
      })
    }
  }

  toggleIndividualDay(event) {
    const checkbox = event.target
    const container = checkbox.closest('.flex')
    const timeInputs = container.querySelectorAll('input[type="time"]')

    timeInputs.forEach(input => {
      input.disabled = !checkbox.checked
    })
  }
}