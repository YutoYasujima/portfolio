import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-scroll"
export default class extends Controller {
  static targets = [
    "container",
    "chatArea",
    "scrollableIcon",
  ];

  static values = {
    machiRepoId: Number,
  };

  connect() {
    this.loading = false;

    // 無限スクロールの要否判定
    const lastPageMarker = document.getElementById("chat-last-page-marker");
    const isLastPage = lastPageMarker?.dataset.lastPage === "true";
    if (!isLastPage) {
      this.containerTarget.addEventListener("scroll", this.onScroll);
      this.scrollableIconTarget.classList.remove("hidden");
    }

    // 画像の表示が終了してから初期表示を行う
    this.waitFormImagesLoaded().then(() => {
      // 最初は一番下へスクロール
      this.scrollToBottom();
      this.containerTarget.classList.remove("invisible");
    });
  }

  disconnect() {
    this.containerTarget.removeEventListener("scroll", this.onScroll);
  }

  // 無限スクロール用トリガー
  onScroll = () => {
    if (this.containerTarget.scrollTop < 300) {
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

    // URLのクエリパラメータ作成
    const params = new URLSearchParams();
    const previousLastData = document.getElementById("chats-previous-last-data");
    params.append("previous_last_created", previousLastData.dataset.previousLastCreated);
    params.append("previous_last_id", previousLastData.dataset.previousLastId);

    const url = `/machi_repos/${this.machiRepoIdValue}/chats/load_more?${params.toString()}`;
    // 次のページ（上方向）を非同期で取得
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      // 日付表示対応
      // 受け取ったTurbo Streamファイルを解析
      // 解析したファイル内にある日付表示がDOM上に既にあった場合は
      // DOM上の表示を削除する
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

      // Turbo Streamの中身を表示する
      Turbo.renderStreamMessage(html);
      // Turbo StreamのHTMLが挿入された後にDOMを見る
      requestAnimationFrame(() => {
        const lastPageMarker = document.getElementById("chat-last-page-marker");
        const isLastPage = lastPageMarker?.dataset.lastPage === "true";
        if (isLastPage) {
          this.containerTarget.removeEventListener("scroll", this.onScroll);
          this.scrollableIconTarget.classList.add("hidden");
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
