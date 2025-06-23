import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="help"
export default class extends Controller {
  static targets = [
    "content",
  ];

  open() {
    this.contentTarget.classList.remove("hidden");
  }

  close() {
    this.contentTarget.classList.add("hidden");
  }
}
