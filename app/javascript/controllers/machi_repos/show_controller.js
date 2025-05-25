import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps } from "../../lib/google_maps_utils";

// Connects to data-controller="machi-repos--show"
export default class extends Controller {
  static targets = [
    "map",
  ];

  static values = {
    apiKey: String,
    mapId: String,
    machiRepo: Object,
  };

  connect() {
    // マーカーをクリアするために保持
    this.markers = [];
    // マーカーの緯度・経度を保持
    this.defaultCoordinates = { lat: this.machiRepoValue.latitude, lng: this.machiRepoValue.longitude };
    // Googleマップのzoomを取得
    this.defaultZoom = 15;
    // Googleマップの導入
    loadGoogleMaps(this.apiKeyValue).then(() => this.initMap());
  }

  // Googleマップの初期化
  async initMap() {
    // 使用するライブラリのインポート
    // JSのMapと分けるため、別名(GoogleMap)を付けてインポート
    const { Map: GoogleMap } = await google.maps.importLibrary("maps");
    const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");

    // Googleマップ初期表示
    this.map = new GoogleMap(this.mapTarget, {
      center: this.defaultCoordinates, // マップの中心座標
      zoom: this.defaultZoom, // マップの拡大
      disableDefaultUI: true,
      zoomControl: true,
      mapId: this.mapIdValue,
    });

    if (this.machiRepoValue.hotspot_settings === "pinpoint") {
      // ピンポイント表示
      const pin = new PinElement({
        background: "hsl(35, 90%, 60%)", // 背景
        borderColor: "hsl(35, 100%, 20%)", // 枠線
        glyphColor: "white",
      });
      this.mainMarker = new AdvancedMarkerElement({
        map: this.map,
        position: this.defaultCoordinates,
        content: pin.element,
        // gmpClickable: true,
        // gmpDraggable: true,
        title: this.addressValue,
      });
      // disconnect時にクリアするためマーカーを保持する
      this.markers.push(this.mainMarker);
    } else {
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
    this.clearMarkers();
      if (this.areaCircle) {
      this.areaCircle.setMap(null); // マップから削除（解放）
      this.areaCircle = null;       // 参照もクリア
    }
    this.map = null;
  }

  // マーカーをすべて解放する
  clearMarkers() {
    this.markers.forEach(marker => marker.setMap(null));
    this.markers = [];
  }
}
