import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-scroll"
export default class extends Controller {
  static targets = [
    "container",
    "chatArea",
  ];

  connect() {
    this.scrollToBottom();

    // 新しいメッセージ追加(DOMの変化)を監視する
    const observer = new MutationObserver(() => this.scrollToBottom());
    // 監視対象の設定と子要素、子孫要素まで監視するかを設定
    observer.observe(this.chatAreaTarget, { childList: true, subtree: false });

    this.observer = observer;
  }

  disconnect() {
    // コンポーネントが切り離されたらObserver停止
    this.observer?.disconnect();
  }

  scrollToBottom() {
    if (this.hasContainerTarget) {
      this.containerTarget.scrollTop = this.containerTarget.scrollHeight;
    }
  }
}
