import { Controller } from "@hotwired/stimulus"
import { MachiVigilStorage } from "../lib/machi_vigil_storage";

// Connects to data-controller="top"
export default class extends Controller {
  connect() {
    // トップページ表示時にストレージをクリアする
    this.storage = new MachiVigilStorage();
    this.storage.clear();
  }
}
