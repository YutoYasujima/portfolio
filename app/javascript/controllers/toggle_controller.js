import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = [
    "content",
  ];

  BREAK_POINT = 768;

  connect() {
    this.chatSection = document.querySelector("#chat-section");
    // ヘッダー + タイトル + ナビゲーション + 入力フォームの高さ合計
    this.elseElementHeight = (80 + 36 + 60 + 45);
    if (this.chatSection) {
      this.windowLastWidth = window.innerWidth;
      this.windowLastHeight = window.innerHeight;
      if (window.innerWidth < this.BREAK_POINT) {
        this.chatSectionHeight = window.innerHeight - (this.contentTarget.clientHeight + this.elseElementHeight);
        this.chatSection.style.height = `${this.chatSectionHeight}px`;
      } else {
        this.chatSectionHeight = this.chatSection.clientHeight;
      }

      window.addEventListener("resize", this.onResizeChatArea);
    }
  }

  disconnect() {
    if (this.chatSection) {
      window.removeEventListener("resize", this.onResizeChatArea);
    }
  }

  // window幅が変更されたとき、チャット領域の高さを変更する
  onResizeChatArea = () => {
    // 表示領域の変更時にチャット領域の高さを修正する
    const diff = this.windowLastHeight - window.innerHeight;
    this.windowLastHeight = window.innerHeight;
    // ウィンドウ高さの差分を追加する
    this.chatSectionHeight -= diff;

    // レスポンシブ対応
    if (this.windowLastWidth < this.BREAK_POINT && window.innerWidth >= this.BREAK_POINT) {
      // 画面幅がモバイル版以上に変わったとき
      this.contentTarget.style.height = null;
      this.chatSection.style.height = '';
      this.windowLastWidth = window.innerWidth;
    } else if (this.windowLastWidth >= this.BREAK_POINT && window.innerWidth < this.BREAK_POINT) {
      // 画面幅がモバイル版に変わったとき
      if (!this.contentTarget.classList.contains("open")) {
        this.contentTarget.classList.add("open");
      }
      this.chatSectionHeight = window.innerHeight - (this.contentTarget.clientHeight + this.elseElementHeight);
      this.chatSection.style.height = `${this.chatSectionHeight}px`;
      this.windowLastWidth = window.innerWidth;
    } else if (window.innerWidth < this.BREAK_POINT) {
      this.chatSection.style.height = `${this.chatSectionHeight}px`;
    }
  }

  toggle(event) {
    const content = this.contentTarget;
    const button = event.currentTarget;
    const chatSection = this.chatSection;

    if (content.classList.contains("open")) {
      // 閉じる処理
      content.classList.remove("open");
       // 一度高さを明示
      content.style.height = `${content.scrollHeight}px`;
      requestAnimationFrame(() => {
        content.style.height = "0px";
      });

      if (chatSection) {
        // contentを閉じた後のチャット領域の高さ
        this.chatSectionHeight = this.chatSectionHeight + content.clientHeight;
        chatSection.style.height = `calc(${this.chatSectionHeight}px)`;
      }
    } else {
      // 開く処理
      content.classList.add("open");
      content.style.height = `${content.scrollHeight}px`;

      content.addEventListener("transitionend", () => {
        // heightをリセット（autoに戻す）
        content.style.height = null;
        if (chatSection) {
          // contentを開いた後のチャット領域の高さ
          this.chatSectionHeight -= content.clientHeight;
          chatSection.style.height = `${this.chatSectionHeight}px`;
        }
      }, {once: true});
    }

    button.classList.toggle("rotate-180");
  }
}
