import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static values = {
    text: String,
  };

  connect() {
    this.overlay = null;
  }

  disconnect() {
    if (this.overlay) {
      this.overlay.remove();
      this.overlay = null;
    }
  }

  confirm(event) {
    event.preventDefault();

    // 要素作成
    const overlay = document.createElement('div');
    const modal = document.createElement('div');
    const text = document.createElement('p');
    const buttonWrapper = document.createElement('div');
    const okButton = document.createElement('button');
    const cancelButton = document.createElement('button');

    // class属性追加
    overlay.classList.add('overlay');
    modal.classList.add('modal');
    text.classList.add('modal-text');
    buttonWrapper.classList.add('modal-button-wrapper');
    okButton.classList.add('modal-button', 'modal-ok');
    cancelButton.classList.add('modal-button', 'modal-cancel');

    // 文字設定
    text.textContent = this.textValue;
    okButton.textContent = 'OK';
    cancelButton.textContent = 'キャンセル';

    // button要素をただのボタンにする
    okButton.type = 'button';
    cancelButton.type = 'button';

    // イベントリスナー設定
    okButton.addEventListener('click', () => {
      // 最も近いform要素のsubmitを行う
      event.target.closest('form').requestSubmit();
    });

    cancelButton.addEventListener('click', () => {
      // モーダルウィンドウを消す
      overlay.remove();
      this.overlay = null;
    });

    overlay.addEventListener('click', () => {
      // モーダルウィンドウを消す
      overlay.remove();
    });

    // 要素を表示
    buttonWrapper.appendChild(okButton);
    buttonWrapper.appendChild(cancelButton);
    modal.appendChild(text);
    modal.appendChild(buttonWrapper);
    overlay.appendChild(modal);
    document.body.appendChild(overlay);

    // プロパティに保持
    this.overlay = overlay;
  }
}
