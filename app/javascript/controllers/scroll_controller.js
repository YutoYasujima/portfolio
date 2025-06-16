import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll"
export default class extends Controller {
  connect() {
  }

  toTop() {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
}
