import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-scroll"
export default class extends Controller {
  static targets = [
    "container",
    "chatArea",
  ];

  connect() {
    // 最初は一番下へスクロール
    this.scrollToBottom();

    // 初期値を保存
    this.previousScrollHeight = this.containerTarget.scrollHeight;

    // DOM変化を監視（チャットメッセージ追加など）
    this.observer = new MutationObserver(this.handleMutations.bind(this));
    this.observer.observe(this.chatAreaTarget, { childList: true, subtree: true });

    // スクロール位置を常に記録
    this.containerTarget.addEventListener("scroll", this.recordScrollPosition);
    this._isNearBottom = true;
  }

  disconnect() {
    this.observer?.disconnect();
    this.containerTarget.removeEventListener("scroll", this.recordScrollPosition);
  }

  // DOMの変化があったときの処理
  handleMutations() {
    const newScrollHeight = this.containerTarget.scrollHeight;

    // 下にいる場合は強制スクロール
    if (this._isNearBottom) {
      setTimeout(() => {
        this.scrollToBottom();
      }, 300);
    } else {
      // 上方向の読み込み(無限スクロール)によるscrollHeight増加分だけ補正
      const diff = newScrollHeight - this.previousScrollHeight;
      if (diff > 0) {
        this.containerTarget.scrollTop += diff;
      }
    }

    // 次回の比較用に記録
    this.previousScrollHeight = newScrollHeight;
  }

  // 強制的に一番下にスクロール
  scrollToBottom() {
    this.containerTarget.scrollTop = this.containerTarget.scrollHeight;
  }

  // スクロール位置を記録して「下にいるかどうか」を判断
  recordScrollPosition = () => {
    const { scrollTop, scrollHeight, clientHeight } = this.containerTarget;
    const threshold = 50; // ピクセル以内なら「下にいる」と判定
    this._isNearBottom = scrollTop + clientHeight >= scrollHeight - threshold;
  }
}
