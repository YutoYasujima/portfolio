import { Controller } from "@hotwired/stimulus"
import consumer from "../../channels/consumer";

// Connects to data-controller="machi-repos--chat"
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
    machiRepoId: Number,
    userId: Number,
  };

  static outlets = [
    "textarea-resize",
  ];

  connect() {
    // 選択中のチャットの削除ボタン
    this.selectedChatButton = null;
    this.timeoutId = null;
    // 削除ボタン表示制御
    this.boundPressStart = this.pressStart.bind(this);
    this.boundCancelPress = this.cancelPress.bind(this);

    // PCイベント
    document.addEventListener("mousedown", this.boundPressStart);
    this.chatAreaTarget.addEventListener("mousedown", this.boundPressStart);
    this.chatAreaTarget.addEventListener("mouseup", this.boundCancelPress);
    this.chatAreaTarget.addEventListener("mouseleave", this.boundCancelPress);

    // モバイルイベント
    document.addEventListener("touchstart", this.boundPressStart);
    this.chatAreaTarget.addEventListener("touchstart", this.boundPressStart);
    this.chatAreaTarget.addEventListener("touchend", this.boundCancelPress);
    this.chatAreaTarget.addEventListener("touchcancel", this.boundCancelPress);

    // 送信中フラグ
    this.isSending = false;
    this.isMessageSending = false;
    this.isImageSending = false;
    // Newアイコンを非表示にする
    this.timeoutId = null;
    this.containerTarget.addEventListener("scroll", this.hiddenNewIcon.bind(this));

    // Action CableによるWebSocket通信
    // 接続情報設定
    this.subscriptionInfo = {
      channel: "MachiRepoChatChannel",
      machi_repo_id: this.machiRepoIdValue,
    };
    // 二重チャネル購読防止
    this.removeExistingSubscription();

    // チャネルの購読開始
    // サーバーのチャネルクラスのsubscribedメソッド呼び出し
    this.subscription = consumer.subscriptions.create(this.subscriptionInfo,
      {
        // メソッド定義
        // ブロードキャスト受信後の処理
        received: async (data) => {
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
                this.newIconTarget.classList.remove("hidden");
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

  // このdisconnectはstimulusのメソッド
  disconnect() {
    // チャネル購読の破棄
    this.removeExistingSubscription();

    this.containerTarget.removeEventListener("scroll", this.hiddenNewIcon.bind(this));

    // PCイベント解除
    document.removeEventListener("mousedown", this.boundPressStart);
    this.chatAreaTarget.removeEventListener("mousedown", this.boundPressStart);
    this.chatAreaTarget.removeEventListener("mouseup", this.boundCancelPress);
    this.chatAreaTarget.removeEventListener("mouseleave", this.boundCancelPress);

    // モバイルイベント解除
    document.removeEventListener("touchstart", this.boundPressStart);
    this.chatAreaTarget.removeEventListener("touchstart", this.boundPressStart);
    this.chatAreaTarget.removeEventListener("touchend", this.boundCancelPress);
    this.chatAreaTarget.removeEventListener("touchcancel", this.boundCancelPress);
  }

  // チャネル購読の破棄
  removeExistingSubscription() {
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
    await fetch(`/machi_repos/${this.machiRepoIdValue}/chats/${chatId}/render_chat`, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
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
      const response = await fetch(`/machi_repos/${this.machiRepoIdValue}/chats`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: formData
      });

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

  // 新着チャット表示
  scrollNewChat() {
    this.containerTarget.scrollTop = this.containerTarget.scrollHeight;
    this.newIconTarget.classList.add("hidden");
  }

  // Newアイコンを非表示にする
  hiddenNewIcon() {
    clearTimeout(this.timeoutId);
    this.timeoutId = setTimeout(() => {
      if (this.isNearBottom()) {
        this.newIconTarget.classList.add("hidden");
      }
    }, 300);
  }

  // スクロールがbottom付近か判定
  isNearBottom() {
    const container = this.containerTarget;
    // bottomからどこまでをnearとするか
    const bottomOffset = 300;
    return container.scrollTop + container.clientHeight >= container.scrollHeight - bottomOffset;
  }

  // チャット長押しで削除ボタン表示
  pressStart(event) {
    clearTimeout(this.timeoutId);
    const chat = event.target.closest(".chat");
    // チャットではない場所または誰かのチャットでmousedownした場合、
    // 表示されている削除ボタンがあれば隠す
    if (!chat || chat.dataset.chatOwn === "others") {
      if (this.selectedChatButton) {
        this.selectedChatButton.closest(".chat").querySelector(".chat-contents-wrapper").classList.remove("shake");
        this.selectedChatButton.classList.add("hidden");
        this.selectedChatButton = null;
      }
      return;
    }

    const chatButton = chat.querySelector("button");
    // ターゲット以外の削除ボタンが表示されていたら非表示にする
    if (this.selectedChatButton && this.selectedChatButton !== chatButton) {
      this.selectedChatButton.closest(".chat").querySelector(".chat-contents-wrapper").classList.remove("shake");
      this.selectedChatButton.classList.add("hidden");
      this.selectedChatButton = null;
    }

    this.timeoutId = setTimeout(() => {
      this.selectedChatButton = chatButton;
      this.selectedChatButton.classList.remove("hidden");
      chat.querySelector(".chat-contents-wrapper").classList.add("shake");
    }, 500);
  }

  // Timeoutクリア
  cancelPress() {
    clearTimeout(this.timeoutId);
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
