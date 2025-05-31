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
  ];

  static values = {
    machiRepoId: Number,
    userId: Number,
  };

  connect() {
    // 送信中フラグ
    this.isMessageSending = false;
    this.isImageSending = false;
    // stimulusコントローラーを保持する
    const controller = this;
    // Newアイコンを非表示にする
    this.timeoutId = null;
    this.containerTarget.addEventListener("scroll", this.hiddenNewIcon.bind(this));

    this.subscription = consumer.subscriptions.create(
      // サーバーのチャネルクラスのsubscribedメソッド呼び出し
      { channel: "MachiRepoChatChannel", machi_repo_id: this.machiRepoIdValue },
      {
        // メソッド定義
        // サーバーから受信
        async received(data) {
          const chatId = data.chat_id;

          // チャット表示
          await controller.fetchChatPartial(chatId);

          // Turbo Streamの描画が終わった後に実行
          requestAnimationFrame(() => {
            // 新着チャット処理
            if (controller.isNearBottom()) {
              // チャット画像の読み込み終了待ち
              controller.waitFormImageLoaded(chatId).then(() => {
                // bottom付近を見ていた場合、最下部へスクロール
                controller.containerTarget.scrollTop = controller.containerTarget.scrollHeight;
              });
            } else {
              // Newアイコンを表示
              controller.newIconTarget.classList.remove("hidden");
            }
          });
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
    this.containerTarget.removeEventListener("scroll", this.hiddenNewIcon.bind(this));
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

  // チャットにメッセージ投稿
  async postMessage(event) {
    event.preventDefault();
    const message = this.textareaTarget.value.trim();
    if (!message) {
      return;
    }

    // 連打対応
    if (this.isMessageSending) {
      return;
    }
    this.isMessageSending = true;

    const formData = new FormData();
    formData.append("chat[message]", message);

    try {
      const response = await fetch(`/machi_repos/${this.machiRepoIdValue}/chats`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: formData
      });

      if (response.ok) {
        this.textareaTarget.value = "";
      } else {
        const errorData = await response.json();
        console.error("送信失敗", errorData.errors);
      }
    } catch (error) {
      console.error("ネットワークエラー", error);
    } finally {
      this.isMessageSending = false;
    }
  }

  // チャットに画像投稿
  async uploadImage(event) {
    event.preventDefault();

    const fileInput = this.fileFieldTarget;
    if (fileInput.files.length <= 0) {
      return;
    }

    // 連打対応
    if (this.isImageSending) {
      return;
    }
    this.isImageSending = true;

    const imageFile = fileInput.files[0];
    const formData = new FormData();
    formData.append("chat[image]", imageFile);

    try {
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
    } catch (error) {
      console.error("ネットワークエラー", error);
    } finally {
      this.isImageSending = false;
    }
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

  // チャット画像が表示されるまで待機
  waitFormImageLoaded(chatId) {
    return new Promise(resolve => {
      const image = this.chatAreaTarget.querySelector(`[data-chat-id="${CSS.escape(chatId)}"] img`);
      if (!image) {
        resolve();
        return;
      }

      // すでに読み込み済みなら即解決
      if (image.complete) {
        resolve();
        return;
      }

      // stimulusコントローラー配下の画像読み込みをチェック
      const checkLoaded = () => resolve();

      image.addEventListener("load", checkLoaded, { once: true });
      image.addEventListener("error", checkLoaded, { once: true });
    });
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
}
