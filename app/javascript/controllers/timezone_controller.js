import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.detectAndSetTimezone()
  }

  detectAndSetTimezone() {
    // Get browser timezone using Intl API
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone

    // Store in cookie for 30 days
    const expirationDate = new Date()
    expirationDate.setDate(expirationDate.getDate() + 30)
    document.cookie = `browser_timezone=${timezone}; expires=${expirationDate.toUTCString()}; path=/`

    // Update hidden field if it exists (for forms)
    const timezoneField = document.getElementById('detected_timezone')
    if (timezoneField) {
      timezoneField.value = timezone
    }
  }
}
