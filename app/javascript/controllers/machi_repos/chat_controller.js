import { Controller } from "@hotwired/stimulus"
import consumer from "../../channels/consumer";

// Connects to data-controller="machi-repos--chat"
export default class extends Controller {
  static targets = [
    "chatArea",
    "defaultChatMine",
    "defaultChatOthers",
    "textareaForm",
    "textarea",
    "fileFieldForm",
    "fileField",
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
          const wrapper = chat.querySelector(".chat-content-wrapper");
          if (data.message) {
            wrapper.classList.add("chat-message-wrapper");
            const p = document.createElement("p");
            p.classList.add("chat-message");
            p.textContent = data.message;
            wrapper.appendChild(p);
          } else if (data.image_url) {
            wrapper.classList.add("chat-image-wrapper");
            const img = document.createElement("img");
            img.classList.add("chat-image");
            img.src = data.image_url;
            wrapper.appendChild(img);
          }
          controller.chatAreaTarget.appendChild(chat);
        },
        // チャットを送信
        sendChat(message) {
          // サーバーのsend_chatメソッドにデータを送信
          return this.perform("send_chat", { message });
        }
      }
    );
  }

  // このdisconnectはstimulusのメソッド
  disconnect() {
    if (this.subscription) {
	    // 購読を破棄する
      this.subscription.unsubscribe();
    }
  }

  // チャットにメッセージ投稿
  postMessage(event) {
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

    this.subscription.sendChat(message);
    this.textareaTarget.value = "";

    // 一定時間後にフラグを解除
    setTimeout(() => {
      this.isSending = false;
    }, 300);
  }

  // チャットに画像投稿
  async uploadImage(event) {
    event.preventDefault();

    const fileInput = this.fileFieldTarget;
    if (fileInput.files.length <= 0) {
      return;
    }

    const imageFile = fileInput.files[0];
    const formData = new FormData();
    formData.append("chat[image]", imageFile);

    const response = await fetch(`/machi_repos/${this.machiRepoIdValue}/chats`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: formData
    });

    if (response.ok) {
      fileInput.value = "";
    } else {
      const errorData = await response.json();
      console.error("送信失敗", errorData.errors);
    }
  }

  toggleChatForm() {
    if (this.textareaFormTarget.classList.contains("hidden")) {
      this.fileFieldFormTarget.classList.add("hidden");
      this.textareaFormTarget.classList.remove("hidden");
    } else {
      this.fileFieldFormTarget.classList.remove("hidden");
      this.textareaFormTarget.classList.add("hidden");
    }
  }
}
