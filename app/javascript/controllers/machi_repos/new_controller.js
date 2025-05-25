import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps, geocoding, reverseGeocoding } from "../../lib/google_maps_utils";

// Connects to data-controller="machi-repos--new"
export default class extends Controller {
  static targets = [
    "map",
    "mytown",
    "search",
    "hotspotAreaRadius",
    "hotspotAreaRadiusSelect",
    "hotspotAttention",
    "displayAddress",
    "address",
    "latitude",
    "longitude",
  ];

  static values = {
    apiKey: String,
    mapId: String,
    latitude: Number,
    longitude: Number,
    address: String,
    machiRepo: Object,
  };

  connect() {
    // マイタウンの緯度・経度を保持
    this.mytownCoordinates = { lat: this.latitudeValue, lng: this.longitudeValue };
    // Googleマップの導入
    loadGoogleMaps(this.apiKeyValue).then(() => this.initMap());
  }

  // Googleマップの初期化
  async initMap() {
		// 使用するライブラリのインポート
    const { Map } = await google.maps.importLibrary("maps");
    const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");

		// Googleマップ初期表示
    this.defaultZoom = 15;
    this.map = new Map(this.mapTarget, {
      center: this.mytownCoordinates, // マップの中心座標
      zoom: this.defaultZoom, // マップの拡大
      disableDefaultUI: true,
      zoomControl: true,
      mapId: this.mapIdValue,
    });

    // メインメインマーカー表示
    const pin = new PinElement({
      background: "hsl(35, 90%, 60%)", // 背景
      borderColor: "hsl(35, 100%, 20%)", // 枠線
      glyphColor: "white",
    });
    this.mainMarker = new AdvancedMarkerElement({
      map: this.map,
      position: this.mytownCoordinates,
      content: pin.element,
      gmpClickable: true,
      gmpDraggable: true,
      title: this.addressValue,
    });

    // エリア指定の円作成
    this.areaCircle = new google.maps.Circle({
      strokeColor: "#00FF00",
      strokeOpacity: 0.8,
      strokeWeight: 2,
      fillColor: "#00FF00",
      fillOpacity: 0.35,
      // map: this.map, // マップのインスタンス
      center: this.mytownCoordinates,
      radius: Number(this.hotspotAreaRadiusSelectTarget.value),
    });
    // エリア指定orピンポイント指定
    if (this.machiRepoValue.hotspot_settings === "area") {
      this.areaCircle.setMap(this.map);
      this.hotspotAreaRadiusTarget.classList.remove("hidden");
    } else {
      this.hotspotAttentionTarget.classList.remove("hidden");
    }

    // マーカーのドラッグエンドイベントリスナー
    this.mainMarker.addListener('dragend', () => this.dragendMarker());
  }

  // マーカードラッグ後の表示
  async dragendMarker() {
    const coordinates = this.mainMarker.position;
    // ドラッグエンド先に合わせて表示変更
    const result = await reverseGeocoding(coordinates);
    this.updateView(result.address, { lat: result.lat, lng: result.lng });
  }

  // マイタウン表示
  async mytownShow() {
    const result = await reverseGeocoding(this.mytownCoordinates);
    this.updateView(result.address, { lat: result.lat, lng: result.lng });
  }

  // 現在位置表示
  async currentLocationShow() {
    // ブラウザに現在地取得機能があるか確認
    if (!navigator.geolocation) {
      alert('ブラウザに現在地取得機能がありません');
      return;
    }

    // 現在地の取得
    try {
      const coordinates = await this.getCurrentCoordinates();
      const result = await reverseGeocoding(coordinates);
      this.updateView(result.address, { lat: result.lat, lng: result.lng });
    } catch (error) {
      console.error('現在地取得エラー:', error);
      alert('現在位置の取得が拒否されました');
    }
  }

  // 現在地の座標取得
  getCurrentCoordinates() {
    return new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(position => {
          resolve({ lat: position.coords.latitude, lng: position.coords.longitude});
        }, (error) => {
          reject(error);
        }, {
          // オプション設定
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0,
        }
      );
    });
  }

  // 検索住所表示
  async searchLocationShow() {
    let address = this.searchTarget.value;
    const result = await geocoding(address);
    // 入力フォームを空にする
    this.searchTarget.value = null;
    // 画面表示更新
    this.updateView(result.address, { lat: result.lat, lng: result.lng });
  }

  // 画面表示の更新
  updateView(address, coordinates) {
    // マップの位置修正
    this.map.setCenter(coordinates);
    // マーカー
    this.mainMarker.title = address;
    this.mainMarker.position = coordinates;
    // エリアの移動
    this.areaCircle.setCenter(coordinates);
    // 住所の表示
    this.displayAddressTarget.textContent = address;
    // hidden属性の値更新
    this.addressTarget.value = address;
    this.latitudeTarget.value = coordinates.lat;
    this.longitudeTarget.value = coordinates.lng;
  }

  // ホットスポット設定変更
  changeHotspotSettings(event) {
    this.hotspotAreaRadiusTarget.classList.toggle('hidden');
    this.hotspotAttentionTarget.classList.toggle('hidden');

    if (event.target.value === "area") {
      // エリア指定
      // エリアの表示
      this.areaCircle.setMap(this.map);
    } else {
      // ピンポイント指定
      // １つ目option要素を選択する
      this.hotspotAreaRadiusSelectTarget.selectedIndex = 0;
      // エリアの非表示と半径の初期化
      this.areaCircle.setMap(null);
      this.areaCircle.setRadius(Number(this.hotspotAreaRadiusSelectTarget.value));
    }
  }

  // エリア半径変更
  changeHotspotAreaRadius(event) {
    this.areaCircle.setRadius(Number(event.target.value));
  }
}