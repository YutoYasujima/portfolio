import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="textarea-resize"
export default class extends Controller {
  static targets = [ "textarea" ];

  connect() {
    this.resize();
  }

  resize() {
    const textarea = this.textareaTarget
    textarea.style.height = "auto"
    textarea.style.height = `${textarea.scrollHeight}px`
  }

  shrink() {
    const textarea = this.textareaTarget
    textarea.style.height = "auto"
  }
}
