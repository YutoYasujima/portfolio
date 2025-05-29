import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-scroll"
export default class extends Controller {
  static targets = [
    "container",
    "chatArea",
  ];

  static values = {
    machiRepoId: Number,
  };

  connect() {
    this.waitFormImagesLoaded().then(() => {
      // 最初は一番下へスクロール
      this.scrollToBottom();
      this.chatAreaTarget.classList.remove("invisible");
      this.chatAreaTarget.classList.add("visible");

      this.loading = false;
      this.currentPage = 1;
      this.containerTarget.addEventListener("scroll", this.onScroll);
    });
  }

  disconnect() {
    this.containerTarget.removeEventListener("scroll", this.onScroll);
  }

  onScroll = () => {
    if (this.containerTarget.scrollTop < 250) {
      // ページ最上部に近づいたとき
      this.loadPreviousPage();
    }
  }

  // 無限スクロール
  loadPreviousPage() {
    if (this.loading) {
      return;
    }
    this.loading = true;
    this.currentPage++;

    const url = `/machi_repos/${this.machiRepoIdValue}/chats/load_more?page=${this.currentPage}`;
    // 次のページ（上方向）を非同期で取得（URLなどは外部から渡してもよい）
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html);
      this.loading = false;
      // Turbo StreamのHTMLが挿入された後にDOMを見る
      requestAnimationFrame(() => {
        const lastPageMarker = document.getElementById("chat-last-page-marker");
        const isLastPage = lastPageMarker?.dataset.lastPage === "true";
        if (isLastPage) {
          this.containerTarget.removeEventListener("scroll", this.onScroll);
        }
      });
    });
  }

  // すべての画像が表示されるまで待つ
  waitFormImagesLoaded() {
    return new Promise(resolve => {
      const images = this.element.querySelectorAll("img");
      if (images.length === 0) {
        resolve();
        return;
      }

      let loadedCount = 0;
      // stimulusコントローラー配下の画像読み込みをチェック
      const checkLoaded = () => {
        loadedCount++;
        if (loadedCount === images.length) {
          resolve();
        }
      };

      images.forEach(img => {
        if (img.complete && img.naturalHeight !== 0) {
          // 既に読み込み済み
          checkLoaded();
        } else {
          img.addEventListener("load", checkLoaded, { once: true });
          img.addEventListener("error", checkLoaded, { once: true });
        }
      });
    });
  }

  // 強制的に一番下にスクロール
  scrollToBottom() {
    this.containerTarget.scrollTop = this.containerTarget.scrollHeight;
  }
}
