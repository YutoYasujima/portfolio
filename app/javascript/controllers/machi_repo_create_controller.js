import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps } from "../google_maps_loader";

// Connects to data-controller="machi-repo-create"
export default class extends Controller {
  static targets = [
    "map",
    "mytown",
    "search",
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
  };

  connect() {
    console.log('machi-repo-create connect');
    loadGoogleMaps(this.apiKeyValue).then(() => this.initMap());
  }

  async initMap() {
    // マイタウンの緯度・経度
    const mytownCoordinates = { lat: this.latitudeValue, lng: this.longitudeValue };

		// 使用するライブラリのインポート
    const { Map, InfoWindow } = await google.maps.importLibrary("maps");
    const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");

		// Googleマップ初期表示
    this.defaultZoom = 15;
    this.map = new Map(this.mapTarget, {
      center: mytownCoordinates, // マップの中心座標
      zoom: this.defaultZoom, // マップの拡大(0:広域 ... 拡大:18？)
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
    this.mainMarker = new AdvancedMarkerElement({
      map: this.map,
      position: mytownCoordinates,
      content: pin.element,
      gmpClickable: true,
      gmpDraggable: true,
      title: this.addressValue,
    });
    // マーカーのドラッグエンドイベントリスナー
    this.mainMarker.addListener('dragend', () => {
      console.log('dragend');
      const coordinates = this.mainMarker.position;
      // ドラッグエンド先に合わせて表示変更
      this.reverseGeocoding(coordinates);
    });
  }

  // マイタウン表示
  mytownShow() {
    console.log('mytown click');
    const coordinates = { lat: this.latitudeValue, lng: this.longitudeValue };
    this.reverseGeocoding(coordinates);
  }

  // 現在位置表示
  currentLocationShow() {
    console.log('currentLocation click');

    // ブラウザに現在地取得機能があるか確認
    if (!navigator.geolocation) {
      alert('ブラウザに現在地取得機能がありません');
      return;
    }

    // 現在地の取得
    navigator.geolocation.getCurrentPosition((position) => {
      const coordinates = {
        lat: position.coords.latitude, // 現在地の緯度取得
        lng: position.coords.longitude, // 現在地の経度取得
      };

      // リバースジオコーディング
      this.reverseGeocoding(coordinates);
    }, () => {
      // ユーザーが位置情報の取得を拒否した場合
      alert(`現在位置の取得が拒否されました`);
    }, {
      // オプション設定
      enableHighAccuracy: true, // 高精度モードを有効化
      timeout: 10000, // 10秒でタイムアウト
      maximumAge: 0, // キャッシュを使わない
    });
  }

  // 検索住所表示
  searchLocationShow() {
    console.log('searchLocation click');
    let address = this.searchTarget.value;
    this.geocoding(address);
  }

  // クライアントでリバースジオコーディング
  async reverseGeocoding(coordinates) {
    const address = await new Promise((resolve, reject) => {
      // リバースジオコーディング
      new google.maps.Geocoder().geocode({ location: coordinates },
        (results, status) => {
        if (status === "OK" && results[0]) {
          resolve(this.getAddressFromGeocodeResult(results[0]));
        } else {
          console.warn("リバースジオコーディング失敗:", status);
          resolve("");
        }
      });
    });
    this.updateView(address, coordinates);
  }

  // クライアントでジオコーディング
  async geocoding(address) {
    let formattedAddress = "";
    const coordinates = await new Promise((resolve, reject) => {
      // ジオコーディング
      new google.maps.Geocoder().geocode({ address: address },
      (results, status) => { // resultは変換結果、statusは処理の状況
        if (status === 'OK' && results[0]) {
          formattedAddress = this.getAddressFromGeocodeResult(results[0]);
          resolve(results[0].geometry.location);
        } else {
          console.warn("ジオコーディング失敗:", status);
          resolve("");
        }
      });
    });
    this.updateView(formattedAddress, coordinates);
  }

  // Googleのgeocodeから表示用住所を取得
  getAddressFromGeocodeResult(result) {
    const components = result.address_components;
    let prefecture = "";
    let city = "";

    components.forEach(component => {
      if (component.types.includes("administrative_area_level_1")) {
        prefecture = component.long_name;
      }
      if (component.types.includes("locality")) {
        city = component.long_name;
      }
    });
    return `${prefecture}${city}`;
  }

  // 画面表示の更新
  updateView(address, coordinates) {
    // マップの位置修正
    this.map.setCenter(coordinates);
    // マーカー
    this.mainMarker.title = address;
    this.mainMarker.position = coordinates;
    // 住所の表示
    this.addressTarget.textContent = address;
    this.latitudeTarget.value = coordinates.lat;
    this.longitudeTarget.value = coordinates.lng;
  }
}
