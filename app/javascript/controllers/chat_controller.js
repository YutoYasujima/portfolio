import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"
import debounce from "../lib/debounce"
import { HEADER_HEIGHT, MOBILE_NAVIGATION_HEIGHT, BREAKPOINT_MOBILE} from "../lib/constants"


// Connects to data-controller="chat"
export default class extends Controller {
  static targets = [
    "container",
    "chatArea",
    "nonChatArea",
    "toggleIcon",
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
    // レスポンシブの状態フラグ
    this.isMobile = window.innerWidth < BREAKPOINT_MOBILE ? true : false;

    // タイトル部分の要素の初期高さを保持しておく
    this.openedNonChatAreaHeight = this.nonChatAreaTarget.clientHeight;
    // トグルバーの高さ
    this.toggleBarAreaHeight = 34;
    // 入力フォームの高さ
    this.inputFormAreaHeight = 40;
    // チャットエリア外の固定要素の合計高さ(ヘッダー、トグルバー、入力フォーム)
    this.nonChatFixAreaHeight = HEADER_HEIGHT + this.toggleBarAreaHeight + this.inputFormAreaHeight;

    // チャットエリアの高さ設定
    this.setChatAreaHeight(() => {
      // 一番下にスクロール
      this.scrollToBottom();
      // ちらつき防止
      this.containerTarget.classList.remove("opacity-0");
    });

    // Action CableによるWebSocket通信
    // 接続情報設定：チャネルクラス名とIDを設定する
    this.subscriptionInfo = {
      channel: this.channelNameValue,
      object_id: this.objectIdValue,
    };
    // 二重チャネル購読防止
    this.removeExistingSubscription();

    // チャネルの購読開始
    this.subscribeChannel();

    this.resizeChatAreaHeight = debounce(() => {
      if (this.isMobile !== window.innerWidth < BREAKPOINT_MOBILE) {
        // レスポンシブの変更あり
        // タイトル部分を表示させておく
        this.nonChatAreaTarget.style.height = null;
        this.nonChatAreaTarget.classList.remove("non-chat-area-close");
        this.toggleIconTarget.classList.remove("rotate-180");
        // リサイズ時にタイトル部分の高さ保持変数の値を変更しておく
        this.openedNonChatAreaHeight = this.nonChatAreaTarget.clientHeight;
        this.isMobile = window.innerWidth < BREAKPOINT_MOBILE ? true : false;
      }

      // スクロール位置保持
      const scrollPosition = this.containerTarget.scrollHeight - this.containerTarget.scrollTop;
      // チャットエリア高さ設定
      this.setChatAreaHeight();
      // スクロール位置反映
      this.containerTarget.scrollTop = this.containerTarget.scrollHeight - scrollPosition;
    }, 200);
    window.addEventListener("resize", this.resizeChatAreaHeight);
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeChatAreaHeight);
  }

  // チャットエリアの高さを設定する
  setChatAreaHeight(func) {
    this.containerTarget.style.height = null;
    // チャットエリアの高さ算出(ビュー高さ-固定要素高さ-タイトル部分-ナビゲーション-余白)
    let chatAreaHeight = window.innerHeight - (this.nonChatFixAreaHeight + this.nonChatAreaTarget.clientHeight + MOBILE_NAVIGATION_HEIGHT + 5);
    this.containerTarget.style.height = `${chatAreaHeight}px`;
    //高さが反映された直後の処理
    func?.();
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

  // 一番下にスクロール
  scrollToBottom() {
    this.containerTarget.scrollTop = this.containerTarget.scrollHeight;
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

  // チャットエリア外の要素の表示/非表示切り替え
  toggleNonChatArea(event) {
    if (this.nonChatAreaTarget.classList.contains("non-chat-area-close")) {
      // チャットエリア外の要素が非表示中
      this.adjustChatAreaHeight(0, this.openedNonChatAreaHeight);
    } else {
      // チャットエリア外の要素が表示中
      this.adjustChatAreaHeight(this.openedNonChatAreaHeight, 0);
    }
    this.nonChatAreaTarget.classList.toggle("non-chat-area-close");
    this.toggleIconTarget.classList.toggle("rotate-180");
  }

  // チャットエリアの高さ調整
  adjustChatAreaHeight(beforeNonChatAreaHeight, afterNonChatAreaHeight) {
    const scrollPosition = this.containerTarget.scrollHeight - this.containerTarget.scrollTop;
    this.containerTarget.classList.add("opacity-0");

    // 一度高さを明示
    this.nonChatAreaTarget.style.height = `${beforeNonChatAreaHeight}px`;
    requestAnimationFrame(() => {
      this.nonChatAreaTarget.style.height = `${afterNonChatAreaHeight}px`;
      this.nonChatAreaTarget.addEventListener("transitionend", () => {
        // チャットエリアの高さを調整する
        this.setChatAreaHeight(() => {
          this.containerTarget.scrollTop = this.containerTarget.scrollHeight - scrollPosition;
          this.containerTarget.classList.remove("opacity-0");
        });
      }, {once: true});
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
