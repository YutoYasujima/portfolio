import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    // closeアイコン
    const svgString = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 -960 960 960" fill="currentColor">
      <path d="m249-207-42-42 231-231-231-231 42-42 231 231 231-231 42 42-231 231 231 231-42 42-231-231-231 231Z"/>
    </svg>
    `;
    const parser = new DOMParser();
    const svgDoc = parser.parseFromString(svgString, "image/svg+xml");
    this.svgElement = svgDoc.documentElement;
  }

  close(event) {
    event.currentTarget.remove();
  }

  // フラッシュメッセージをクリアする
  clear() {
    this.element.replaceChildren();
  }

  // alertフラッシュメッセージ表示
  showAlertMessage({ detail: { message }}) {
    // 要素作成
    const div = document.createElement("div");
    div.className = "fixed bottom-15 left-0 w-full z-5 md:bottom-8";
    const ul = document.createElement("ul");
    const li = document.createElement("li");
    li.classList.add("flash", "flash-alert");
    li.dataset.action = "click->flash#close";
    const text = document.createElement("span");
    text.classList.add("flash-text");
    text.textContent = message;
    const svgWrap = document.createElement("span");
    svgWrap.classList.add("flash-close-icon", "flash-close-icon-alert");

    // 要素の組み立て
    svgWrap.appendChild(this.svgElement.cloneNode(true));
    li.appendChild(text);
    li.appendChild(svgWrap);
    ul.appendChild(li);
    div.appendChild(ul);

    // 表示
    this.element.replaceChildren(div);
  }
}
