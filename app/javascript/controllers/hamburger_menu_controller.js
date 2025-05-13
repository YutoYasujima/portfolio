import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="hamburger-menu"
export default class extends Controller {
  static targets = [
    "menu",
    "cover",
  ];

  connect() {
  }

  toggleMenu() {
    this.menuTarget.classList.toggle('hidden');
    this.coverTarget.classList.toggle('hidden');
  }
}
