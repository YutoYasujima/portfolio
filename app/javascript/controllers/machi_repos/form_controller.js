import { Controller } from "@hotwired/stimulus"
import { geocoding, reverseGeocoding } from "../../lib/google_maps_utils";

// Connects to data-controller="machi-repos--form"
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
    machiRepo: Object,
    mytownLatitude: Number,
    mytownLongitude: Number,
  };

  connect() {
    // マップ保持
    this.map = null;
    // メインマーカー保持
    this.mainMarker = null;
    // デフォルトの座標保持
    this.defaultCoordinates = null;
     // マイタウンの座標保持
    this.mytownCoordinates = {
      lat: this.mytownLatitudeValue,
      lng: this.mytownLongitudeValue,
    };
  }

  disconnect() {
     // マーカーのイベントリスナー削除
    if (this.dragendListener) {
      this.dragendListener.remove();
      this.dragendListener = null;
    }

    // マーカーと円をマップから外す
    if (this.mainMarker) {
      this.mainMarker.setMap(null);
      this.mainMarker = null;
    }

    if (this.areaCircle) {
      this.areaCircle.setMap(null);
      this.areaCircle = null;
    }

    this.map = null;
  }

  // Googleマップの初期化
  // google_maps_controller.jsのconnect処理後に実行
  async initMap({ detail: { mapInfo }}) {
		// Googleマップオブジェクト取得
    this.map = mapInfo.map;

    // メインマーカー表示
    this.mainMarker = mapInfo.mainMarker;

    // デフォルトの座標取得
    this.defaultCoordinates = { lat: mapInfo.latitude, lng: mapInfo.longitude };

    // エリア指定の円作成
    this.areaCircle = new google.maps.Circle({
      strokeColor: "#00FF00",
      strokeOpacity: 0.8,
      strokeWeight: 2,
      fillColor: "#00FF00",
      fillOpacity: 0.35,
      center: this.defaultCoordinates,
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
    this.dragendListener = this.mainMarker.addListener("dragend", () => this.dragendMarker());
  }

  // マーカードラッグ後の表示
  async dragendMarker() {
    const coordinates = this.mainMarker.position;
    // ドラッグエンド先に合わせて表示変更
    const result = await reverseGeocoding(coordinates);
    this.updateView(result.address, { lat: result.lat, lng: result.lng });
  }

  // マイタウン表示
  async showMytown() {
    const result = await reverseGeocoding(this.mytownCoordinates);
    this.updateView(result.address, { lat: result.lat, lng: result.lng });
  }

  // 現在位置表示
  async showCurrentLocation() {
    // ブラウザに現在地取得機能があるか確認
    if (!navigator.geolocation) {
      alert("ブラウザに現在地取得機能がありません");
      return;
    }

    // 現在地の取得
    try {
      const coordinates = await this.getCurrentCoordinates();
      const result = await reverseGeocoding(coordinates);
      this.updateView(result.address, { lat: result.lat, lng: result.lng });
    } catch (error) {
      console.error("現在地取得エラー:", error);
      alert("現在位置の取得が拒否されました");
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
  async showSearchLocation() {
    let address = this.searchTarget.value;
    if (!address.trim()) {
      return;
    }
    await geocoding(address)
    .then(data => {
      // 画面表示更新
      this.updateView(data.address, { lat: data.lat, lng: data.lng });
    })
    .catch(error => {
      const errorType = error?.error;
      let message = "不明なエラーが発生しました";

      if (errorType === "geocode_failed") {
        message = "住所の検索に失敗しました";
      } else if (errorType === "not_japan") {
        message = "日本国内の住所を入力してください";
      } else if (errorType === "missing_prefecture_or_city") {
        message = "都道府県または市区町村を特定できませんでした";
      }

      // フラッシュメッセージ表示
      this.callFlashAlert(message);
    });
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
    // 住所検索の入力フォームを空にする
    this.searchTarget.value = null;
    // フラッシュメッセージが表示されていたらクリアする
    this.callFlashClear();
  }

  // ホットスポット設定変更
  changeHotspotSettings(event) {
    this.hotspotAreaRadiusTarget.classList.toggle("hidden");
    this.hotspotAttentionTarget.classList.toggle("hidden");

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

  // flashコントローラーを利用してフラッシュメッセージをクリアする
  callFlashClear() {
    this.dispatch("flash-clear", { detail: { content: "" } });
  }
  // flashコントローラーを利用して、alertフラッシュメッセージを表示する
  callFlashAlert(message) {
    this.dispatch("flash-alert", { detail: { message } });
  }
}