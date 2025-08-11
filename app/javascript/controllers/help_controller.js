import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="help"
export default class extends Controller {
  static targets = [
    "overlay",
    "frame",
    "items",
    "item",
    "indicator",
  ];

  connect() {
    this.currentIndex = 0;
    this.changeIndicator();
  }

  open() {
    this.currentIndex = 0;
    this.overlayTarget.classList.remove("hidden");
    this.changeIndicator();
    // 背景のスクロールを禁止
    document.body.classList.add("overflow-hidden");
  }

  close() {
    this.currentIndex = 0;
    this.frameTarget.scrollTop = 0;
    this.overlayTarget.classList.add("hidden");
    this.itemsTarget.style.transform = `translateX(0px)`;
    this.changeIndicator();
    // 背景のスクロールを解禁
    document.body.classList.remove("overflow-hidden");
  }

  // アイテムを表示
  showItem(event) {
    this.currentIndex = event.currentTarget.dataset.carouselIndicatorNum;
    this.frameTarget.scrollTop = 0;
    this.itemsTarget.style.transform = `translateX(${-this.itemsTarget.clientWidth * this.currentIndex}px)`;
    this.changeIndicator();
  }

  // インディケーターの現在位置を表示
  changeIndicator() {
    this.indicatorTargets.forEach(indicator => {
      indicator.classList.add("opacity-30");
    });
    this.indicatorTargets[this.currentIndex].classList.remove("opacity-30");
  }
}
