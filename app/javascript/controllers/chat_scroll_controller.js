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

      // 無限スクロールの要否判定
      const lastPageMarker = document.getElementById("chat-last-page-marker");
      const isLastPage = lastPageMarker?.dataset.lastPage === "true";
      if (!isLastPage) {
        this.containerTarget.addEventListener("scroll", this.onScroll);
      }
    });
  }

  disconnect() {
    this.containerTarget.removeEventListener("scroll", this.onScroll);
  }

  onScroll = () => {
    if (this.containerTarget.scrollTop < 500) {
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
      // 日付表示対応
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, "text/html");
      const streamElements = doc.querySelectorAll("turbo-stream");
      streamElements.forEach(streamEl => {
        const templateContent = streamEl.querySelector("template")?.content;
        const chatDates = templateContent?.querySelectorAll("[data-chat-date]");
        chatDates?.forEach(chatDate => {
          const date = chatDate.dataset.chatDate;
          const existedChatDates = this.chatAreaTarget.querySelectorAll(`[data-chat-date="${CSS.escape(date)}"]`);
          existedChatDates.forEach(existedChatDate => {
            existedChatDate.remove();
          });
        });
      });

      // Turbo Streamの中身を処理する
      Turbo.renderStreamMessage(html);
      // Turbo StreamのHTMLが挿入された後にDOMを見る
      requestAnimationFrame(() => {
        const lastPageMarker = document.getElementById("chat-last-page-marker");
        const isLastPage = lastPageMarker?.dataset.lastPage === "true";
        if (isLastPage) {
          this.containerTarget.removeEventListener("scroll", this.onScroll);
        }
        this.loading = false;
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
