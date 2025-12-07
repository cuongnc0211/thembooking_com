import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["weekdaysTimes", "saturdayTimes", "sundayTimes"]

  toggleDay(event) {
    const target = event.target.dataset.target
    const timesTarget = this[`${target}TimesTarget`]
    const inputs = timesTarget.querySelectorAll("input")

    inputs.forEach(input => {
      input.disabled = !event.target.checked
    })
  }
}