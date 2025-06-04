import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = [
    "content",
  ];

  connect() {
    this.chatSection = document.querySelector("#chat-section");
    this.chatSectionHeight = this.chatSection.clientHeight;
    console.log('chatSectionHeight: %s', this.chatSectionHeight);
    window.addEventListener("resize", () => {
    });
  }

  disconnect() {
  }

  toggle(event) {
    const content = this.contentTarget;
    const button = event.currentTarget;
    const chatSection = document.querySelector("#chat-section");

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
        this.chatSectionBeforeHeight = chatSection.clientHeight;
        chatSection.style.height = `calc(${this.chatSectionBeforeHeight}px + ${content.clientHeight}px)`;
      }
    } else {
      // 開く処理
      content.classList.add("open");
      content.style.height = `${content.scrollHeight}px`;

      content.addEventListener("transitionend", function handler() {
        // heightをリセット（autoに戻す）
        content.style.height = null;
        content.removeEventListener("transitionend", handler);
      });

      if (chatSection) {
        // contentを開いた後のチャット領域の高さ
        chatSection.style.height = `${this.chatSectionBeforeHeight}px`;
      }
    }

    button.classList.toggle("rotate-180");
  }
}
