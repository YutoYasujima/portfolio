import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tag"
export default class extends Controller {
  static targets = [
    "inputTagName",
    "tagNames",
    "tags",
  ];

  connect() {
    // タグの数を管理
    this.tagCount = 0;
    // タグ表示
    this.displayTags();
  }

    // 画面表示時にタグ表示
  displayTags() {
    const tagNames = this.tagNamesTarget.value;
    if (!tagNames) {
      return;
    }
    // タグ表示領域をクリアする
    this.tagsTarget.innerHTML = "";
    // タグの数だけ表示する
    tagNames.split(",").forEach(tagName => {
      this.createTag(tagName);
    });
  }

  // 表示用タグ作成
  createTag(tagName) {
    const tagElement = document.querySelector(".default-tag").cloneNode(true);
    const hashtaggedTagName = "#" + tagName;
    tagElement.dataset.tagName = tagName;
    tagElement.querySelector(".tag-text").textContent = hashtaggedTagName;
    tagElement.classList.remove("default-tag");
    this.tagsTarget.appendChild(tagElement);
  }

  // タグ追加
  appendTag() {
    const MAX_TAG_COUNT = 3;
    const input = this.inputTagNameTarget.value;
    if (this.tagCount >= MAX_TAG_COUNT || input.trim().length === 0) {
      return;
    }
    this.inputTagNameTarget.value = null;
    // カンマ区切りで配列に変換、空文字要素を排除
    const tagNamesArray = input.split(",").map(str => str.trim()).filter(str => str !== "");
    const length = tagNamesArray.length;
    for (let i = 0; i < length; i++) {
      // タグが合計３つ作成されていたら終了
      if (this.tagCount >= MAX_TAG_COUNT) {
        break;
      }
      // マルチバイト文字対応するため、文字列を配列に変換
      // 15番目までの要素を結合し、再度文字列化
      let processedTagName = Array.from(tagNamesArray[i]).slice(0, 15).join("");
      // hidden属性のvalue内に既にあるタグ(重複)なら次のループへ
      if (this.tagNamesTarget.value.split(",").includes(processedTagName)) {
        continue;
      }

      // 表示用タグ作成
      this.createTag(processedTagName);

      // hiddenフォームにタグを保持
      // ２つ目以降のタグはカンマで繋ぐ
      if (this.tagNamesTarget.value.trim() !== "") {
        processedTagName = "," + processedTagName;
      }
      this.tagNamesTarget.value += processedTagName;
      this.tagCount += 1;
    }
  }

  // タグ削除
  deleteTag(event) {
    const deleteTagName = event.currentTarget.dataset.tagName;
    // hiddenフォームに保持されているタグを更新
    const newTagNamesArray = this.tagNamesTarget.value.split(",").filter(tagName => tagName !== deleteTagName );
    this.tagNamesTarget.value = newTagNamesArray.join(",");
    event.currentTarget.remove();
    this.tagCount -= 1;
  }
}
