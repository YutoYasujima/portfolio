import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps, geocoding, reverseGeocoding } from "../../lib/google_maps_utils";

// Connects to data-controller="machi-repo--index"
export default class extends Controller {
  static targets = [
      "map",
      "mytown",
      "search",
      "address",
      "latitude",
      "longitude",
      "mapFrame",
      "addIcon",
      "removeIcon",
      "searchFormWrapper",
      "searchForm",
      "inputTitle",
      "inputInfoLevel",
      "inputCategory",
      "inputTagNames",
      "inputTagMatchTypeOr",
      "inputDisplayRangeRadius",
      "inputDisplayHotspotCount",
      "inputStartDate",
      "inputEndDate",
      "hiddenAddress",
      "hiddenLatitude",
      "hiddenLongitude",
    ];

    static values = {
      apiKey: String,
      mapId: String,
      latitude: Number,
      longitude: Number,
      address: String,
      machiRepos: Array,
    };

    connect() {
      // マーカーをクリアするために保持
      this.markers = [];
      // マイタウンの緯度・経度を保持
      this.defaultCoordinates = { lat: this.latitudeValue, lng: this.longitudeValue };
      // input[type="hidden"]に値を保持
      this.hiddenAddressTarget.value = this.addressValue;
      this.hiddenLatitudeTarget.value = this.latitudeValue;
      this.hiddenLongitudeTarget.value = this.longitudeValue;
      // Googleマップのzoomを取得
      this.defaultZoom = Number(localStorage.getItem("mapZoom")) || 14;
      // Googleマップの導入
      loadGoogleMaps(this.apiKeyValue).then(() => this.initMap());
    }

    disconnect() {
      this.clearMarkers();
      this.map = null;
    }

    clearMarkers() {
      this.markers.forEach(marker => marker.setMap(null));
      this.markers = [];
    }

    onClickSearchFormWindow() {
      this.searchFormWrapperTarget.classList.toggle("invisible-element");
      this.addIconTarget.classList.toggle("hidden");
      this.removeIconTarget.classList.toggle("hidden");
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

      // 周辺のまちレポマーカー表示
      await this.createMachiRepoMarkers();

      // メインメインマーカー表示
      // 周辺のまちレポマーカーよりも上に表示させるため最後に表示する
      const pin = new PinElement({
        background: "hsl(35, 90%, 60%)", // 背景
        borderColor: "hsl(35, 100%, 20%)", // 枠線
        glyphColor: "white",
      });
      this.mainMarker = new AdvancedMarkerElement({
        map: this.map,
        position: this.defaultCoordinates,
        content: pin.element,
        gmpClickable: true,
        gmpDraggable: true,
        title: this.addressValue,
      });
      // マーカーのドラッグエンドイベントリスナー
      this.mainMarker.addListener("dragend", () => this.onDragendMarker());
      // disconnect時にクリアするためマーカーを保持する
      this.markers.push(this.mainMarker);
    }

    // 周辺のまちレポマーカー表示
    async createMachiRepoMarkers() {
      const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");
      // 表示するマーカーの位置が重なっていた場合、スパイラル状に少しずらす
      // 先にメインマーカーの座標を登録
      const locationMap = new Map();
      // 小数点以下を少し削り座標を曖昧にすることで、
      // 重なる可能性のあるマーカーをずらす対象にする
      let key = `${this.defaultCoordinates.lat.toFixed(5)}:${this.defaultCoordinates.lng.toFixed(5)}`;
      // key: 座標, value: 同座標の数
      locationMap.set(key, 1);
      const convertMachiRepos = this.spiralSpreadMarkers(this.machiReposValue, locationMap);

      // 0:share, 1:warn, 2: emergency
      convertMachiRepos.forEach(machiRepo => {
        let borderColor = "#0000ff";
        let glyphColor = "#5d5df5";
        let glyph = "🎈"
        // まちレポの情報レベルに応じてマーカーの色を変更
        switch (machiRepo.info_level) {
          // 共有:share
          case "share":
            glyphColor = "hsl(120, 90%, 60%)";
            borderColor = "hsl(120, 100%, 40%)";
            break;
          // 警告:warn
          case "warn":
            glyphColor = "hsl(50, 90%, 60%)";
            borderColor = "hsl(50, 100%, 40%)";
            break;
          // 緊急: emergency
          case "emergency":
            glyphColor = "hsl(0, 90%, 60%)";
            borderColor = "hsl(0, 100%, 40%)";
            break;
        }
        switch (machiRepo.category) {
          case "crime":
            glyph = "🚨";
            break;
          case "disaster":
            glyph = "🌀";
            break;
          case "traffic":
            glyph = "🚦";
            break;
          case "children":
            glyph = "🧒";
            break;
          case "animal":
            glyph = "🐶";
            break;
          case "environment":
            glyph = "🏠";
            break;
        }
        const pin = new PinElement({
          glyph: glyph,
          background: glyphColor, // 背景
          borderColor: borderColor, // 枠線
          glyphColor: "#FFFFFF",
        });
        const marker = new AdvancedMarkerElement({
          map: this.map,
          position: { lat: machiRepo.convertLatitude, lng: machiRepo.convertLongitude },
          content: pin.element,
          gmpClickable: true,
          title: machiRepo.address,
        });

        // InfoWindowの作成
        const infoWindow = new google.maps.InfoWindow({
          content: `<div>
          <strong>${machiRepo.address}</strong><br>
          <a href="/machi_repos/${machiRepo.id}">詳細ページへ</a>
          </div>`
        });

        // マーカークリックでInfoWindow表示
        marker.addEventListener("gmp-click", () => {
          infoWindow.open({
            anchor: marker,
            map: this.map,
            shouldFocus: false,
          });
        });

        // disconnect時にクリアするためマーカーを保持する
        this.markers.push(marker);
      });
    }

    // 重なっているマーカーの座標をスパイラル状に変換
    spiralSpreadMarkers(machiRepos, locationMap) {
      const spreadRadius = 0.0003;
      return machiRepos.map(machiRepo => {
        const key = `${machiRepo.latitude.toFixed(5)}:${machiRepo.longitude.toFixed(5)}`;
        const count = locationMap.get(key) || 0;
        locationMap.set(key, count + 1);

        const angle = count * 0.5;
        const radius = spreadRadius * count;

        const latOffset = Math.cos(angle) * radius;
        const lngOffset = Math.sin(angle) * radius;

        machiRepo.convertLatitude = machiRepo.latitude + latOffset;
        machiRepo.convertLongitude = machiRepo.longitude + lngOffset;

        return machiRepo;
      });
    }

    // マーカードラッグ後の表示
    onDragendMarker() {
      const position = this.mainMarker.position;
      // 検索フォームの値を更新
      // リバースジオコーディングため緯度・経度のみ送信
      this.hiddenAddressTarget.value = null;
      this.hiddenLatitudeTarget.value = position.lat;
      this.hiddenLongitudeTarget.value = position.lng;
      localStorage.setItem("mapZoom", this.map.getZoom());
      this.searchFormTarget.requestSubmit();
    }

    // マイタウン表示
    onClickMytownIcon() {
      // 検索フォームの値を更新
      // マイタウンはサーバーで取得する
      this.hiddenAddressTarget.value = null;
      this.hiddenLatitudeTarget.value = null;
      this.hiddenLongitudeTarget.value = null;
      localStorage.setItem("mapZoom", this.map.getZoom());
      this.searchFormTarget.requestSubmit();
    }

    // 現在位置表示
    onClickCurrentLocationIcon() {
      // ブラウザに現在地取得機能があるか確認
      if (!navigator.geolocation) {
        alert("ブラウザに現在地取得機能がありません");
        return;
      }

      // 現在地の取得
      navigator.geolocation.getCurrentPosition(position => {
        // 検索フォームの値を更新
        // リバースジオコーディングするため緯度・経度のみ送信
        this.hiddenAddressTarget.value = null;
        this.hiddenLatitudeTarget.value = position.coords.latitude;
        this.hiddenLongitudeTarget.value = position.coords.longitude;
        localStorage.setItem("mapZoom", this.map.getZoom());
        this.searchFormTarget.requestSubmit();
      }, (error) => {
        console.error("現在地位置情報の取得に失敗:", error)
      }, {
        // オプション設定
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
      });
    }

    // 検索住所表示
    onClickSearchLocationButtton() {
      const address = this.searchTarget.value;
      // 検索フォームの値を更新
      // ジオコーディングするため住所のみ送信
      this.hiddenAddressTarget.value = address;
      this.hiddenLatitudeTarget.value = null;
      this.hiddenLongitudeTarget.value = null;
      localStorage.setItem("mapZoom", this.map.getZoom());
      this.searchFormTarget.requestSubmit();
    }

    // 検索フォーム
    onClickSearchFormButton() {
      // リバースジオコーディングするため緯度・経度のみ送信
      this.hiddenAddressTarget.value = null;
      localStorage.setItem("mapZoom", this.map.getZoom());
      this.searchFormTarget.requestSubmit();
    }

    // 検索フォーム入力クリア
    onClickSearchFormClearIcon() {
      this.inputTitleTarget.value = "";
      this.inputInfoLevelTarget.value = "";
      this.inputCategoryTarget.value = "";
      this.inputTagNamesTarget.value = "";
      this.inputTagMatchTypeOrTarget.checked = true;
      this.inputDisplayRangeRadiusTarget.value = 1000;
      this.inputDisplayHotspotCountTarget.value = 20;
      this.inputStartDateTarget.value = "";
      this.inputEndDateTarget.value = "";
    }
}
