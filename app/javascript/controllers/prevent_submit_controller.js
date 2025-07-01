import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="prevent-submit"
export default class extends Controller {
  submit(event) {
    // Enterキーによるsubmitを防止
    if (event.key === "Enter") {
      event.preventDefault();
    }
  }
}
