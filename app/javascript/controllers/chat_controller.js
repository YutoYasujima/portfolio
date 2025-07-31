import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = [
    "container",
    "chatArea",
    "textareaForm",
    "textarea",
    "fileFieldForm",
    "fileField",
    "newIcon",
    "spinner",
  ];

  static values = {
    controllerName: String,
    channelName: String,
    objectId: Number,
  };

  static outlets = [
  "textarea-resize",
  ];

  connect() {
    // チャット送信中フラグ
    this.isSending = false;
    // Action CableによるWebSocket通信
    // 接続情報設定
    // チャネルクラス名とIDを設定する
    this.subscriptionInfo = {
      channel: this.channelNameValue,
      object_id: this.objectIdValue,
    };
    // 二重チャネル購読防止
    this.removeExistingSubscription();

    // チャネルの購読開始
    this.subscribeChannel();
  }

  // チャネル購読
  subscribeChannel() {
    // サーバーのチャネルクラスのsubscribedメソッド呼び出し
    // subscriptionInfoのデータをパラメータとしてチャネルに接続
    this.subscription = consumer.subscriptions.create(this.subscriptionInfo,
      {
        // メソッド定義
        // ブロードキャスト受信後の処理
        received: async (data) => {
          console.log('received');
          const chatId = data.chat_id;
          if (data.type === "create") {
            // チャット表示
            await this.fetchChatPartial(chatId);

            // Turbo Streamの描画が終わった後に実行
            requestAnimationFrame(() => {
              // 新着チャット処理
              if (this.isNearBottom()) {
                // bottom付近を見ていた場合、最下部へスクロール
                this.containerTarget.scrollTop = this.containerTarget.scrollHeight;
              } else {
                // Newアイコンを表示
                // this.newIconTarget.classList.remove("hidden");
              }
            });
          } else if (data.type === "destroy") {
            if (Number(data.user_id) === Number(this.userIdValue)) {
              // 自分のチャットを消すのはTurbo Streamで行っている
              requestAnimationFrame(() => {
                this.selectedChatButton = null;
              });
              return;
            }

            // 誰かがチャットを削除した場合、画面からチャットを消す
            const chat = this.chatAreaTarget.querySelector(`#${CSS.escape(`chat_${chatId}`)}`);
            if (chat) {
              chat.remove();
              this.selectedChatButton = null;
            }
          }
        }
      }
    );
  }

  // チャネル購読の破棄
  removeExistingSubscription() {
    if (!this.subscriptionInfo) {
      return;
    }

    const identifier = JSON.stringify(this.subscriptionInfo);

    // チャネルの購読が存在する場合は削除
    const existing = consumer.subscriptions.subscriptions.find(sub => sub.identifier === identifier);
    if (existing) {
      consumer.subscriptions.remove(existing);
    }

    this.subscription = null;
  }

  // 部分テンプレート取得によるチャット表示
  async fetchChatPartial(chatId) {
    await fetch(`/${this.controllerNameValue}/${this.objectIdValue}/chats/${chatId}/render_chat`, {
      headers: { "Accept": "text/vnd.turbo-stream.html" }
    })
    .then(response => response.text())
    .then(html => {
      // チャット表示
      // Turbo Streamの中身を表示する
      Turbo.renderStreamMessage(html);
    })
    .catch(error => {
      console.error("部分テンプレートの取得に失敗:", error);
    });
  }

  // スクロールがbottom付近か判定
  isNearBottom() {
    const container = this.containerTarget;
    // bottomからどこまでをnearとするか
    const bottomOffset = 300;
    return container.scrollTop + container.clientHeight >= container.scrollHeight - bottomOffset;
  }

  // メッセージ or 画像用form表示切り替え
  toggleChatForm() {
    if (this.textareaFormTarget.classList.contains("hidden")) {
      this.fileFieldFormTarget.classList.add("hidden");
      this.textareaFormTarget.classList.remove("hidden");
    } else {
      this.fileFieldFormTarget.classList.remove("hidden");
      this.textareaFormTarget.classList.add("hidden");
    }
  }

  // チャットデータ送信
  async sendChatData({ formData, resetTarget }) {
    if (this.isSending) {
      return;
    }
    // 表示中のフラッシュメッセージがあれば削除
    this.callFlashClear();
    this.isSending = true;
    // 待機中表示
    this.spinnerTarget.classList.remove("hidden");

    try {
      const response = await fetch(`/${this.controllerNameValue}/${this.objectIdValue}/chats`,
        {
          method: "POST",
          headers: {
            "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
          },
          body: formData
        }
      );

      if (response.ok) {
        resetTarget.value = "";
      } else {
        const errorData = await response.json();
        console.error("送信失敗", errorData.errors);
        // フラッシュメッセージ表示
        this.callFlashAlert(errorData.errors);
      }
    } catch (error) {
      console.error("ネットワークエラー", error);
    } finally {
      this.isSending = false;
      // 待機中表示解除
      this.spinnerTarget.classList.add("hidden");
    }
  }

  // メッセージ投稿
  async postMessage(event) {
    event.preventDefault();

    const message = this.textareaTarget.value.trim();
    if (!message) {
      return;
    }

    const formData = new FormData();
    formData.append("chat[message]", message);

    await this.sendChatData({
      formData,
      resetTarget: this.textareaTarget,
    });

    this.textareaResizeOutlet?.resize();
  }

  // 画像投稿
  async uploadImage(event) {
    event.preventDefault();

    const fileInput = this.fileFieldTarget;
    if (fileInput.files.length <= 0) {
      return;
    }

    const formData = new FormData();
    formData.append("chat[image]", fileInput.files[0]);

    await this.sendChatData({
      formData,
      resetTarget: fileInput,
    });
  }

  // flashコントローラーを利用してフラッシュメッセージをクリアする
  callFlashClear() {
    this.dispatch("flash-clear", { detail: { content: "" } });
  }

  // flashコントローラーを利用して、alertフラッシュメッセージを表示する
  callFlashAlert(message) {
    this.dispatch("flash-alert", { detail: { message } });
  }
}
