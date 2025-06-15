import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reload"
export default class extends Controller {
  reload() {
    // Turboのキャッシュをクリア
    Turbo.cache.clear();

    // ページ遷移後にスクロールを行う
    document.addEventListener("turbo:load", this.scrollToTarget, { once: true });

    // Turboで現在のURLを再訪問（履歴は上書き）
    Turbo.visit(window.location.href, { action: "replace" });
  }

  scrollToTarget() {
    const element = document.getElementById("target-element");
    if (element) {
      // スムースにスクロール（または instant にも変更可能）
      element.scrollIntoView({ block: "start" });
    }
  }
}
