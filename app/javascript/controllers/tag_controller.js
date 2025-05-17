import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tag"
export default class extends Controller {
  static targets = [
    "inputTagName",
    "tagNames",
    "tags",
  ];

  connect() {
    console.log('tag');
    // タグの数を管理
    this.tagCount = 0;
    // タグ表示
    this.displayTag();
  }

    // 画面表示時にタグ表示
  displayTag() {
    const tagNames = this.tagNamesTarget.value;
    if (!tagNames) {
      return;
    }
    tagNames.split(',').forEach(tagName => {
      this.createTag(tagName);
    });
  }

  // 表示用タグ作成
  createTag(tagName) {
    const tagElement = document.querySelector('.default-tag').cloneNode(true);
    const hashtaggedTagName = '#' + tagName;
    tagElement.dataset.tagName = tagName;
    tagElement.querySelector('.tag-text').textContent = hashtaggedTagName;
    tagElement.classList.remove('default-tag');
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
    const tagNamesArray = input.split(',');
    const length = tagNamesArray.length;
    for (let i = 0; i < length; i++) {
      // タグが合計３つ作成されていたら終了
      if (this.tagCount >= MAX_TAG_COUNT) {
        break;
      }
      // タグ文字列の整形
      let processedTagName = Array.from(tagNamesArray[i].trim()).slice(0, 10).join('');
      // hidden属性のvalue内に既にあるタグなら次のループへ(重複チェック)
      if (this.tagNamesTarget.value.split(',').includes(processedTagName)) {
        continue;
      }

      // 表示用タグ作成
      this.createTag(processedTagName);

      // hiddenフォームにタグを保持
      // ２つ目以降のタグはカンマで繋ぐ
      if (this.tagNamesTarget.value.trim() !== '') {
        processedTagName = ',' + processedTagName;
      }
      this.tagNamesTarget.value += processedTagName;
      this.tagCount += 1;
    }
  }

  // タグ削除
  deleteTag(event) {
    const deleteTagName = event.currentTarget.dataset.tagName;
    // hiddenフォームに保持されているタグを更新
    const newTagNamesArray = this.tagNamesTarget.value.split(',').filter(tagName => tagName !== deleteTagName );
    this.tagNamesTarget.value = newTagNamesArray.join(',');
    event.currentTarget.remove();
    this.tagCount -= 1;
  }
}
