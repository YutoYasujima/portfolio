import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="infinite-scroll"
export default class extends Controller {
  static targets = [
    "lastPageMarker",
    "previousLastUpdated",
    "previousLastId",
    "container",
    "scrollableIcon",
  ];

  static values = {
    controllerName: String,
    actionName: String,
  };

  connect() {
    // 無限スクロールフラグ
    this.loading = false;

    // 無限スクロールの要否判定
    const isLastPage = this.lastPageMarkerTarget.value === "true";
    if (!isLastPage) {
      window.addEventListener("scroll", this.onScroll);
      this.scrollableIconTarget.classList.remove("hidden");
    }
  }

  disconnect() {
    // イベントリスナー削除
    window.removeEventListener("scroll", this.onScroll);
  }

  // 無限スクロール用トリガー
  onScroll = () => {
    const rect = this.containerTarget.getBoundingClientRect();
    if (rect.bottom <= window.innerHeight + 300) {
      this.loadPreviousPage({controller: this.controllerNameValue, action: this.actionNameValue});
    }
  }

  // 無限スクロール
  loadPreviousPage({ controller, action }) {
    if (this.loading) {
      return;
    }
    this.loading = true;

    // 送信データ取得
    const params = new URLSearchParams();
    // 最終データの更新日時
    params.append("previous_last_updated", this.previousLastUpdatedTarget.value);
    // 最終データのID
    params.append("previous_last_id", this.previousLastIdTarget.value);

    const url = `/${controller}/${action}?${params.toString()}`;
    // 次のページ（下方向）を非同期で取得
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      // Turbo Streamの中身を表示する
      Turbo.renderStreamMessage(html);
      // Turbo StreamのHTMLが挿入された後にDOMを見る
      requestAnimationFrame(() => {
        const isLastPage = this.lastPageMarkerTarget.value === "true";
        if (isLastPage) {
          window.removeEventListener("scroll", this.onScroll);
          this.scrollableIconTarget.classList.add("hidden");
        }
        this.loading = false;
      });
    });
  }
}
