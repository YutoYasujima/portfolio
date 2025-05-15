import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps } from "../google_maps_loader";

// Connects to data-controller="machi-repo-create"
export default class extends Controller {
  static targets = [
    "map",
    "mytown",
    "search",
    "hotspotAreaRadius",
    "hotspotAreaRadiusSelect",
    "hotspotAttention",
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
    // マイタウンの緯度・経度を保持
    this.mytownCoordinates = { lat: this.latitudeValue, lng: this.longitudeValue };
    loadGoogleMaps(this.apiKeyValue).then(() => this.initMap());
  }

  async initMap() {
		// 使用するライブラリのインポート
    const { Map, InfoWindow } = await google.maps.importLibrary("maps");
    const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");

		// Googleマップ初期表示
    this.defaultZoom = 15;
    this.map = new Map(this.mapTarget, {
      center: this.mytownCoordinates, // マップの中心座標
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
      position: this.mytownCoordinates,
      content: pin.element,
      gmpClickable: true,
      gmpDraggable: true,
      title: this.addressValue,
    });

    // エリア指定の円描画
    this.areaCircle = new google.maps.Circle({
      strokeColor: "#00FF00",
      strokeOpacity: 0.8,
      strokeWeight: 2,
      fillColor: "#00FF00",
      fillOpacity: 0.35,
      map: this.map, // マップのインスタンス
      center: this.mytownCoordinates,
      radius: Number(this.hotspotAreaRadiusSelectTarget.value),
    });

    // マーカーのドラッグエンドイベントリスナー
    this.mainMarker.addListener('dragend', () => {
      const coordinates = this.mainMarker.position;
      // ドラッグエンド先に合わせて表示変更
      this.reverseGeocoding(coordinates);
    });

  }

  // マイタウン表示
  mytownShow() {
    this.reverseGeocoding(this.mytownCoordinates);
  }

  // 現在位置表示
  currentLocationShow() {
    // ブラウザに現在地取得機能があるか確認
    if (!navigator.geolocation) {
      alert('ブラウザに現在地取得機能がありません');
      return;
    }
    // 現在地の取得
    navigator.geolocation.getCurrentPosition((position) => {
      // 現在地の緯度・経度取得
      const coordinates = {
        lat: position.coords.latitude,
        lng: position.coords.longitude,
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

  // Googleマップのgeocode機能の処理結果から表示用住所を取得
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
    // エリアの移動
    this.areaCircle.setCenter(coordinates);
    // 住所の表示
    this.addressTarget.textContent = address;
    this.latitudeTarget.value = coordinates.lat;
    this.longitudeTarget.value = coordinates.lng;
  }

  // ホットスポット設定変更
  changeHotspotSettings(event) {
    const area = 0;     // エリア指定
    const pinpoint = 1; // ピンポイント指定
    this.hotspotAreaRadiusTarget.classList.toggle('hidden');
    this.hotspotAttentionTarget.classList.toggle('hidden');

    if (Number(event.target.value) === area) {
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
