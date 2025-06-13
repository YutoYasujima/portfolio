export class MachiVigilStorage {
  // アプリ名をキーとする
  #app = "machi_vigil";
  // 利用するストレージ
  #storage = sessionStorage;
  // ストレージから読み込んだオブジェクト
  #data;

  constructor() {
    // 登録済みのデータを取得、無ければ空のオブジェクト
    this.#data = JSON.parse(this.#storage[this.#app] || "{}");
  }

  // 指定されたキーでデータを取得
  getItem(key) {
    return this.#data[key];
  }

  // キーとバリューを設定
  setItem(key, value) {
    this.#data[key] = value;
  }

  // データ削除
  removeItem(key) {
    delete this.#data[key]
  }

  // ストレージにデータを保存
  save() {
    this.#storage[this.#app] = JSON.stringify(this.#data);
  }

  // アプリで利用しているストレージデータをすべて削除
  clear() {
    this.#storage.removeItem(this.#app);
  }
}