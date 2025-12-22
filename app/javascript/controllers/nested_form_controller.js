import { Controller } from "@hotwired/stimulus"
import NestedForm from "stimulus-rails-nested-form"

// Connects to data-controller="nested-form"
export default class extends NestedForm {
  connect() {
    super.connect()
    console.log("NestedForm controller connected!")
    console.log("Targets:", this.element.querySelectorAll('[data-nested-form-target="item"]').length)
  }

  add(e) {
    console.log("Add button clicked")
    super.add(e)
  }

  remove(e) {
    console.log("Remove button clicked", e.currentTarget)
    super.remove(e)
  }
}
