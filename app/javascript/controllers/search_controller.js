import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = [
    "addIcon",
    "removeIcon",
    "contents",
    "searchForm",
    "inputValue",
  ];

  connect() {
  }

  toggle(event) {
    this.addIconTarget.classList.toggle("hidden");
    this.removeIconTarget.classList.toggle("hidden");
    this.contentsTarget.classList.toggle("search-contents-close");
  }

  submit(event) {
    event.preventDefault();
    this.searchFormTarget.requestSubmit();
  }
}
