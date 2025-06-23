import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="accordion"
export default class extends Controller {
  // アコーディオン
  toggle(event) {
    const trigger = event.currentTarget;
    const item = trigger.closest(`[data-accordion-target="item"]`);
    const content = item.querySelector(`[data-accordion-target="content"]`);
    const openIcon = item.querySelector(`[data-accordion-target="openIcon"]`);
    const closeIcon = item.querySelector(`[data-accordion-target="closeIcon"]`);

    if (content.classList.contains("accordion-content-close")) {
      // 既に開かれているitemがあれば閉じる
      const openContent = this.element.querySelector(".accordion-content-open");
      if (openContent) {
        openContent.classList.remove("accordion-content-open");
        openContent.classList.add("accordion-content-close");
        const openItem = openContent.closest(`[data-accordion-target="item"]`);
        openItem.querySelector(`[data-accordion-target="openIcon"]`).classList.remove("hidden");
        openItem.querySelector(`[data-accordion-target="closeIcon"]`).classList.add("hidden");
      }
      // クリックしたitemを開く
      content.classList.remove("accordion-content-close");
      content.classList.add("accordion-content-open");
      openIcon.classList.add("hidden");
      closeIcon.classList.remove("hidden");
    } else {
      // クリックしたitemを閉じる
      content.classList.add("accordion-content-close");
      openIcon.classList.remove("hidden");
      closeIcon.classList.add("hidden");
    }

    item.addEventListener("transitionend", () => {
      // itemのトップにスクロールする
      item.scrollIntoView({
        behavior: "smooth",
        block: "start",
      });
    }, { once: true });
  }
}
