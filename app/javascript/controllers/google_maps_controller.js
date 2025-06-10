import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps } from "../lib/google_maps_utils";

// Connects to data-controller="google-maps"
export default class extends Controller {
  static targets = [
    "map",
  ];

  static values = {
    apiKey: String,
    mapId: String,
    latitude: Number,
    longitude: Number,
    address: String,
  };

  async connect() {
    this.map = null;
    this.coordinates = { lat: this.latitudeValue, lng: this.longitudeValue };
    this.defaultZoom = 15;
    await loadGoogleMaps(this.apiKeyValue);
    await this.createMap();

    // オリジナルイベントを発生させる
    this.dispatch("google-maps-connected", { detail: { mapInfo: {
      map: this.map,
      mainMarker: this.mainMarker,
    } } });
  }

  disconnect() {
    if (this.mainMarker) {
      this.mainMarker.setMap(null);
      this.mainMarker = null;
    }

    this.map = null;
  }

  async createMap() {
    // 使用するライブラリのインポート
    const { Map } = await google.maps.importLibrary("maps");
    const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");

		// Googleマップ初期表示
    this.map = new Map(this.mapTarget, {
      center: this.coordinates, // マップの中心座標
      zoom: this.defaultZoom, // マップの拡大
      disableDefaultUI: true,
      zoomControl: true,
      mapId: this.mapIdValue,
    });

    // メインマーカー表示
    const pin = new PinElement({
      background: "hsl(35, 90%, 60%)", // 背景
      borderColor: "hsl(35, 100%, 20%)", // 枠線
      glyphColor: "white",
    });
    this.mainMarker = new AdvancedMarkerElement({
      map: this.map,
      position: this.coordinates,
      content: pin.element,
      gmpClickable: true,
      gmpDraggable: true,
      title: this.addressValue,
    });
  }
}
