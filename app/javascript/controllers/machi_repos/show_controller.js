import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="machi-repos--show"
export default class extends Controller {
  static values = {
    machiRepo: Object,
  };

  connect() {
    // マップ保持
    this.map = null;
    // メインマーカー保持
    this.mainMarker = null;
    // デフォルトの座標を保持
    this.defaultCoordinates = null;
  }

  // Googleマップの初期化
  async initMap({ detail: { mapInfo }}) {
    // Googleマップオブジェクト取得
    this.map = mapInfo.map;

    // メインマーカー取得
    this.mainMarker = mapInfo.mainMarker;

    // デフォルトの座標取得
    this.defaultCoordinates = { lat: mapInfo.latitude, lng: mapInfo.longitude };

    // エリア指定時の設定
    if (this.machiRepoValue.hotspot_settings === "area") {
      // メインマーカーをマップから外す
      this.mainMarker.setMap(null);
      // エリア指定の円描画
      this.areaCircle = new google.maps.Circle({
        strokeColor: "#00FF00",
        strokeOpacity: 0.8,
        strokeWeight: 2,
        fillColor: "#00FF00",
        fillOpacity: 0.35,
        map: this.map, // マップのインスタンス
        center: this.defaultCoordinates,
        radius: Number(this.machiRepoValue.hotspot_area_radius),
      });
    }
  }

  disconnect() {
    // メモリへの影響を考慮し解放しておく
    if (this.areaCircle) {
      this.areaCircle.setMap(null); // マップから削除（解放）
      this.areaCircle = null;       // 参照もクリア
    }

    if (this.mainMarker) {
      this.mainMarker.setMap(null);
      this.mainMarker = null;
    }

    this.map = null;
  }
}
