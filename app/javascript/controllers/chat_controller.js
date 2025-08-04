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
    "lastPageMarker",
    "previousLastCreated",
    "previousLastId",
    "scrollableIcon",
  ];

  static values = {
    controllerName: String,
    channelName: String,
    objectId: Number,
  };

  static outlets = [
    "textarea-resize",
  ];

  initialize() {
    // インスタンス内変数初期化処理
    // 読み込み中フラグ
    this.isLoading = false;
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

    // 選択中のチャットの削除ボタン
    this.selectedChatButton = null;
    this.timeoutId = null;
  }

  connect() {
    // チャットエリアの高さ設定
    this.setChatAreaHeight(() => {
      // 一番下にスクロール
      this.scrollToBottom();
      // ちらつき防止
      this.containerTarget.classList.remove("opacity-0");
    });

    // 無限スクロールの要否判定
    const isLastPage = this.lastPageMarkerTarget.value === "true";
    if (!isLastPage) {
      this.containerTarget.addEventListener("scroll", this.infiniteScroll);
      this.scrollableIconTarget.classList.remove("hidden");
    }

    // チャネルの購読開始
    this.subscribeChannel();

    // 画面リサイズ時のチャット画面の高さ調整
    window.addEventListener("resize", this.resizeChatAreaHeight);
    // Newアイコンを非表示にする
    this.containerTarget.addEventListener("scroll", this.hiddenNewIcon);
    // チャット長押しで削除表示(PC)
    document.addEventListener("mousedown", this.pressStart);
    this.chatAreaTarget.addEventListener("mousedown", this.pressStart);
    this.chatAreaTarget.addEventListener("mouseup", this.cancelPress);
    this.chatAreaTarget.addEventListener("mouseleave", this.cancelPress);
    // チャット長押しで削除表示(モバイル)
    document.addEventListener("touchstart", this.pressStart);
    this.chatAreaTarget.addEventListener("touchstart", this.pressStart);
    this.chatAreaTarget.addEventListener("touchend", this.cancelPress);
    this.chatAreaTarget.addEventListener("touchcancel", this.cancelPress);
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeChatAreaHeight);

    this.containerTarget.removeEventListener("scroll", this.infiniteScroll);
    this.containerTarget.removeEventListener("scroll", this.hiddenNewIcon);

    document.removeEventListener("mousedown", this.pressStart);
    this.chatAreaTarget.removeEventListener("mousedown", this.pressStart);
    this.chatAreaTarget.removeEventListener("mouseup", this.cancelPress);
    this.chatAreaTarget.removeEventListener("mouseleave", this.cancelPress);
    // チャット長押しで削除表示(モバイル)
    document.removeEventListener("touchstart", this.pressStart);
    this.chatAreaTarget.removeEventListener("touchstart", this.pressStart);
    this.chatAreaTarget.removeEventListener("touchend", this.cancelPress);
    this.chatAreaTarget.removeEventListener("touchcancel", this.cancelPress);
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
    // Action CableによるWebSocket通信
    // 接続情報設定：チャネルクラス名とIDを設定する
    this.subscriptionInfo = {
      channel: this.channelNameValue,
      object_id: this.objectIdValue,
    };
    // 二重チャネル購読防止
    this.removeExistingSubscription();
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

  // 画面のリサイズによるチャットエリア高さの対応
  resizeChatAreaHeight = debounce(() => {
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

  // 無限スクロール用トリガー
  infiniteScroll = () => {
    if (this.containerTarget.scrollTop < 400) {
      // ページ最上部に近づいたとき
      this.loadPreviousPage();
    }
  }

  // 無限スクロール
  loadPreviousPage() {
    if (this.loading) {
      return;
    }
    this.loading = true;

    // URLのクエリパラメータ作成
    const params = new URLSearchParams();
    params.append("previous_last_created", this.previousLastCreatedTarget.value);
    params.append("previous_last_id", this.previousLastIdTarget.value);

    const url = `/${this.controllerNameValue}/${this.objectIdValue}/chats/load_more?${params.toString()}`;
    // 次のページ（上方向）を非同期で取得
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      // 日付表示対応
      // 受け取ったTurbo Streamファイルを解析
      // 解析したファイル内にある日付表示がDOM上に既にあった場合は
      // DOM上の表示を削除する
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, "text/html");
      const streamElements = doc.querySelectorAll("turbo-stream");
      streamElements.forEach(streamEl => {
        const templateContent = streamEl.querySelector("template")?.content;
        const chatDates = templateContent?.querySelectorAll("[data-chat-date]");
        chatDates?.forEach(chatDate => {
          const date = chatDate.dataset.chatDate;
          const existedChatDates = this.chatAreaTarget.querySelectorAll(`[data-chat-date="${CSS.escape(date)}"]`);
          existedChatDates.forEach(existedChatDate => {
            existedChatDate.remove();
          });
        });
      });

      // Turbo Streamの中身を表示する
      Turbo.renderStreamMessage(html);
      // Turbo StreamのHTMLが挿入された後にDOMを見る
      requestAnimationFrame(() => {
        const isLastPage = this.lastPageMarkerTarget.value === "true";
        if (isLastPage) {
          this.containerTarget.removeEventListener("scroll", this.infiniteScroll);
          this.scrollableIconTarget.classList.add("hidden");
        }
        this.loading = false;
      });
    });
  }

  // 新着チャット表示クリックで最下部へスクロール
  scrollNewChat() {
    this.containerTarget.scrollTop = this.containerTarget.scrollHeight;
    this.newIconTarget.classList.add("hidden");
  }

  // Newアイコンを非表示にする
  hiddenNewIcon = debounce(() => {
    if (this.isNearBottom()) {
      this.newIconTarget.classList.add("hidden");
    }
  }, 200);

  pressStart = (event) => {
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
  cancelPress = () => {
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
