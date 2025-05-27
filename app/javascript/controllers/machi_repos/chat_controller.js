import { Controller } from "@hotwired/stimulus"
import consumer from "../../channels/consumer";

// Connects to data-controller="machi-repos--chat"
export default class extends Controller {
  static targets = [
    "chatArea",
    "defaultChatMine",
    "defaultChatOthers",
    "textarea",
  ];

  static values = {
    machiRepoId: Number,
    userId: Number,
  };

  connect() {
    // 送信中フラグ
    this.isSending = false;
    // stimulusコントローラーを保持する
    const controller = this;

    this.subscription = consumer.subscriptions.create(
      // サーバーのチャネルクラスのsubscribedメソッド呼び出し
      { channel: "MachiRepoChatChannel", machi_repo_id: this.machiRepoIdValue },
      {
        // メソッド定義
        // サーバーから受信
        received(data) {
          // 画面に表示する
          let chat = null;
          if (Number(data.user_id) === Number(controller.userIdValue)) {
            // 自分のチャット表示
            chat = controller.defaultChatMineTarget.children[0].cloneNode(true);
          } else {
            // 他人のチャット表示
            chat = controller.defaultChatOthersTarget.children[0].cloneNode(true);
            chat.querySelector(".chat-nickname").textContent = data.nickname;
          }
          const date = new Date(data.time).toLocaleTimeString("ja-JP", {
            hour: "2-digit",
            minute: "2-digit",
            hour12: false,
          });
          chat.querySelector(".chat-time time").textContent = date;
          chat.querySelector(".chat-message").textContent = data.message;
          controller.chatAreaTarget.appendChild(chat);
        },
        // チャットを送信
        sendChat({ user_id, message, image }) {
          // サーバーのsend_chatメソッドにデータを送信
          return this.perform("send_chat", { user_id, message, image });
        }
      }
    );
  }

  onClickSendButton(event) {
    event.preventDefault();
    const message = this.textareaTarget.value.trim();
    if (!message) {
      return;
    }
    // １回のタッチで２回クリックイベントが発火してしまう対応
    if (this.isSending) {
      return;
    }
    this.isSending = true;

    this.subscription.sendChat({ user_id: this.userIdValue, message: message, image: null });
    this.textareaTarget.value = "";

    // 一定時間後にフラグを解除（例：300ms）
    setTimeout(() => {
      this.isSending = false;
    }, 300);
  }

  // このdisconnectはstimulusのメソッド
  disconnect() {
    if (this.subscription) {
	    // 購読を破棄する
      this.subscription.unsubscribe();
    }
  }
}
