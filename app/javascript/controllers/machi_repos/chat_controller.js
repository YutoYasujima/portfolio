import { Controller } from "@hotwired/stimulus"
import consumer from "../../channels/consumer";

// Connects to data-controller="machi-repos--chat"
export default class extends Controller {
  static targets = [
    "container",
    "chatArea",
    "defaultChatMine",
    "defaultChatOthers",
    "defaultChatDate",
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
        received(data) {
          // 今日の日付表示追加
          controller.insertTodayLabel();

          // チャット表示
          const chat = controller.createChat(data);
          controller.chatAreaTarget.appendChild(chat);

          // 新着チャット処理
          if (controller.isNearBottom()) {
            // チャット画像の読み込み終了待ち
            controller.waitFormImageLoaded(chat).then(() => {
              // bottom付近を見ていた場合、最下部へスクロール
              controller.containerTarget.scrollTop = controller.containerTarget.scrollHeight;
            });
          } else {
            // Newアイコンを表示
            controller.newIconTarget.classList.remove("hidden");
          }
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
    this.containerTarget.removeEventListener("scroll", this.hiddenNewIcon.bind(this));
  }

  // チャットにメッセージ投稿
  postMessage(event) {
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

    this.subscription.sendChat(message);
    this.textareaTarget.value = "";

    // 一定時間後に連打フラグを解除
    setTimeout(() => {
      this.isMessageSending = false;
    }, 300);
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

  // 取得したデータを元にチャット作成
  createChat(data) {
    // 画面に表示する
    let chat = null;
    if (Number(data.user_id) === Number(this.userIdValue)) {
      // 自分のチャット表示
      chat = this.defaultChatMineTarget.children[0].cloneNode(true);
    } else {
      // 他人のチャット表示
      chat = this.defaultChatOthersTarget.children[0].cloneNode(true);
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
      // メッセージ表示
      wrapper.classList.add("chat-message-wrapper");
      const p = document.createElement("p");
      p.classList.add("chat-message");
      p.textContent = data.message;
      wrapper.appendChild(p);
    } else if (data.image_url) {
      // 画像表示
      wrapper.classList.add("chat-image-wrapper");
      const img = document.createElement("img");
      img.classList.add("chat-image");
      img.src = data.image_url;
      wrapper.appendChild(img);
    }

    return chat;
  }

  // チャット前に今日の日付を表示する
  insertTodayLabel() {
    const now = new Date(Date.now());
    const fmtDate = new Intl.DateTimeFormat("ja-JP", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    });
    const latestDate = fmtDate.format(now);
    const formattedLatestDate = latestDate.replaceAll("/", "-");
    const existedChatDate = this.chatAreaTarget.querySelector(`[data-chat-date="${CSS.escape(formattedLatestDate)}"]`);

    if (!existedChatDate) {
      const fmtWeekday = new Intl.DateTimeFormat("ja-JP", {
        weekday: "short",
      });
      const displayDate = `${latestDate}(${fmtWeekday.format(now)})`;
      const template = this.defaultChatDateTarget.children[0].cloneNode(true);
      template.dataset.chatDate = formattedLatestDate;
      template.querySelector(".chat-date").textContent = displayDate;
      this.chatAreaTarget.appendChild(template);
    }
  }

  // チャット画像が表示されるまで待機
  waitFormImageLoaded(chat) {
    return new Promise(resolve => {
      const image = chat.querySelector("img");
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
