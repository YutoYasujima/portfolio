import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="hamburger-menu"
export default class extends Controller {
  static targets = [
    "menu",
    "cover",
  ];

  toggleMenu() {
    this.menuTarget.classList.toggle("hidden");
    this.coverTarget.classList.toggle("hidden");
  }

  disconnect() {
    this.menuTarget.classList.add("hidden");
    this.coverTarget.classList.add("hidden");
  }
}
