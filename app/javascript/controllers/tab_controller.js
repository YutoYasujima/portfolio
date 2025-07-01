import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tab"
export default class extends Controller {
  static targets = [
    "progressIndicators",
    "itemWrapper",
    "prevButton",
    "nextButton",
    "submitButton",
  ];

  static values = {
    isError: Boolean,
  }

  connect() {
    this.currentIndex = 0;
    this.progressed = 0;
    this.itemCount = this.itemWrapperTarget.children.length;

    // SVGアイコン
    const labelSvgString = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960" fill="currentColor">
        <path d="m80-160 243.23-320L80-800h527q14.25 0 27 6.37 12.75 6.38 21 17.63l225 296-224 296q-8.25 11.25-21 17.62-12.75 6.38-27 6.38H80Zm120-60h407l198-260-198-260H200l198 260-198 260Zm303-260Z"/>
      </svg>
    `;
    const labelFullSvgString = `
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960" fill="currentColor">
        <path d="m80-160 243.23-320L80-800h527q14.25 0 27 6.37 12.75 6.38 21 17.63l225 296-224 296q-8.25 11.25-21 17.62-12.75 6.38-27 6.38H80Z"/>
      </svg>
    `;

    // バリデーションエラーがあった時、最後のタブを表示する
    if (this.isErrorValue) {
      this.currentIndex = this.itemCount - 1;
      this.progressed = this.currentIndex;
      [...this.itemWrapperTarget.children].forEach(item => {
        item.classList.add("hidden");
      });
      this.itemWrapperTarget.children[this.currentIndex].classList.remove("hidden");
    }

    // 進捗表示
    const parser = new DOMParser();
    this.labelSvgDoc = parser.parseFromString(labelSvgString, "image/svg+xml");
    this.labelFullSvgDoc = parser.parseFromString(labelFullSvgString, "image/svg+xml");
    this.labelSvgElement = this.labelSvgDoc.documentElement;
    this.labelFullSvgElement = this.labelFullSvgDoc.documentElement;
    this.showProgressIndicators();

    // ボタン表示
    this.toggleButtons();
  }

  // 前へボタンクリックイベントリスナー
  prev() {
    if (this.currentIndex <= 0) {
      return;
    }
    window.scrollTo({ top: 0 });
    this.itemWrapperTarget.children[this.currentIndex].classList.add("hidden");
    this.currentIndex -= 1;
    this.itemWrapperTarget.children[this.currentIndex].classList.remove("hidden");
    this.toggleButtons();
    this.showProgressIndicators();
  }

  // 次へボタンクリックイベントリスナー
  next() {
    if (this.currentIndex >= this.itemCount - 1) {
      return;
    }
    window.scrollTo({ top: 0 });
    this.itemWrapperTarget.children[this.currentIndex].classList.add("hidden");
    this.currentIndex += 1;
    this.itemWrapperTarget.children[this.currentIndex].classList.remove("hidden");
    if (this.progressed < this.currentIndex) {
      this.progressed = this.currentIndex;
    }
    this.toggleButtons();
    this.showProgressIndicators();
  }

  // 進捗表示
  showProgressIndicators() {
    this.progressIndicatorsTarget.replaceChildren();
    for (let i = 0; i < this.itemCount; i++) {
      const div = document.createElement("div");
      div.classList.add("w-10", "aspect-square");
      div.dataset.index = i;
      if (i === this.currentIndex) {
        div.classList.add("text-[#F5A83D]");
        div.appendChild(this.labelFullSvgElement.cloneNode(true));
      } else if (i <= this.progressed) {
        div.classList.add("text-[#fad6a4]");
        div.dataset.action = "click->tab#showTab";
        div.appendChild(this.labelFullSvgElement.cloneNode(true));
      } else {
        div.appendChild(this.labelSvgElement.cloneNode(true));
      }
      this.progressIndicatorsTarget.appendChild(div);
    }
  }

  // 進捗のクリックイベントリスナー
  showTab(event) {
    this.currentIndex = Number(event.currentTarget.dataset.index);
    [...this.itemWrapperTarget.children].forEach(item => {
      item.classList.add("hidden");
    });
    this.itemWrapperTarget.children[this.currentIndex].classList.remove("hidden");
    window.scrollTo({ top: 0 });
    this.toggleButtons();
    this.showProgressIndicators();
  }

  // ボタン表示切り替え
  toggleButtons() {
    this.togglePrevButton();
    this.toggleNextButton();
    this.toggleSubmitButton();
  }

  // 前へボタン表示制御
  togglePrevButton() {
    if (this.currentIndex <= 0) {
      this.prevButtonTarget.classList.add("invisible", "pointer-events-none");
    } else {
      this.prevButtonTarget.classList.remove("invisible", "pointer-events-none");
    }
  }

  // 次へボタン表示制御
  toggleNextButton() {
    if (this.currentIndex >= this.itemCount - 1) {
      this.nextButtonTarget.classList.add("invisible", "pointer-events-none");
    } else {
      this.nextButtonTarget.classList.remove("invisible", "pointer-events-none");
    }
  }

  // 登録ボタン表示制御
  toggleSubmitButton() {
    if (this.currentIndex >= this.itemCount - 1) {
      this.submitButtonTarget.classList.remove("hidden");
    } else {
      this.submitButtonTarget.classList.add("hidden");
    }
  }
}
