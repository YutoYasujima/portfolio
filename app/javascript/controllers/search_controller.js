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

  clear() {
    // ページのリロードを行う
    // Turboのキャッシュをクリア
    Turbo.cache.clear();
    // Turboで現在のURLを再訪問（履歴は上書き）
    Turbo.visit(window.location.href, { action: "replace" });
  }
}
