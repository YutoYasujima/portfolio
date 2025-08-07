import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loading"
export default class extends Controller {
  static targets = [
    "overlay",
  ];

  connect() {
    this.button = null;
    // 初期表示時にローディンをオンにしているためstopする
    requestAnimationFrame(() => {
      this.stop();
    });
  }

  // ローディングアニメーション
  start = (event) => {
    // 連打防止
    this.button = event.target;
    this.button.disabled = true;
    this.overlayTarget.classList.remove("hidden");
  }

  stop = () => {
    this.overlayTarget.classList.add("hidden");
    if (this.button) {
      this.button.disabled = false;
      this.button = null;
    }
  }
}
