import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps } from "../google_maps_loader";

// Connects to data-controller="machi-repo-create"
export default class extends Controller {
  static targets = [
    "map",
  ];

  static values = {
    apiKey: String,
    mapId: String,
  };

  connect() {
    console.log('machi-repo-create connect');
    loadGoogleMaps(this.apiKeyValue).then(() => this.initMap());
  }

  async initMap() {
    // 東京駅の緯度・経度
    const tokyoStation = {lat: 35.6812996, lng: 139.7670658};

		// 使用するライブラリのインポート
		// 「google.maps.～」と書かずにすむようになる。
    const { Map, InfoWindow } = await google.maps.importLibrary("maps");
    const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");
    const { Geocoder } = await google.maps.importLibrary("geocoding");

		// Googleマップ初期表示
    this.map = new Map(this.mapTarget, {
      center: tokyoStation, // マップの中心座標
      zoom: 15, // マップの拡大(0:広域 ... 拡大:18？)
      disableDefaultUI: true,
      zoomControl: true,
      // fullscreenControl: true,
      mapId: this.mapIdValue,
    });

    // メインメインマーカー表示
    const pin = new PinElement({
      background: "hsl(35, 90%, 60%)", // 背景
      borderColor: "hsl(35, 100%, 20%)", // 枠線
      glyphColor: "white",
    });
    const marker= new AdvancedMarkerElement({
      map: this.map,
      position: tokyoStation,
      content: pin.element,
      gmpClickable: true,
      gmpDraggable: true,
      title: "Tokyo Station",
    });

    // マーカーウィンドウ
    const infoWindow = new InfoWindow({
      content: `lat:${tokyoStation['lat']}, lnt: ${tokyoStation['lng']}`,
    });
  }
}
