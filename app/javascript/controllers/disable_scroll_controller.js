import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="disable-scroll"
export default class extends Controller {
  connect() {
    document.body.style.overflow = "hidden"
  }

  disconnect() {
    document.body.style.overflow = ""
  }
}
