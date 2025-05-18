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
      this.markers = [];
      // マイタウンの緯度・経度を保持
      this.defaultCoordinates = { lat: this.latitudeValue, lng: this.longitudeValue };
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

    // Googleマップの初期化
    async initMap() {
      // 使用するライブラリのインポート
      // JSのMapと分けるため、別名(GoogleMap)を付けてインポート
      const { Map: GoogleMap } = await google.maps.importLibrary("maps");
      const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");

      // Googleマップ初期表示
      this.defaultZoom = 14;
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
      this.mainMarker.addListener('dragend', () => this.dragendMarker());
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
        // まちレポの情報レベルに応じてマーカーの色を変更
        switch (machiRepo.info_level) {
          // 共有:share
          case 'share':
            glyphColor = "hsl(120, 90%, 60%)";
            borderColor = "hsl(120, 100%, 40%)";
            break;
          // 警告:warn
          case 'warn':
            glyphColor = "hsl(50, 90%, 60%)";
            borderColor = "hsl(50, 100%, 40%)";
            break;
          // 緊急: emergency
          case 'emergency':
            glyphColor = "hsl(0, 90%, 60%)";
            borderColor = "hsl(0, 100%, 40%)";
            break;
        }
        const pin = new PinElement({
          background: glyphColor, // 背景
          borderColor: borderColor, // 枠線
          glyphColor: glyphColor,
        });
        const marker = new AdvancedMarkerElement({
          map: this.map,
          position: { lat: machiRepo.convertLatitude, lng: machiRepo.convertLongitude },
          content: pin.element,
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
        marker.addListener('click', () => {
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
      const spreadRadius = 0.0005;
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
    dragendMarker() {
      const position = this.mainMarker.position;
      const coords = {
        latitude: position.lat,
        longitude: position.lng
      };

      this.fetchMachiRepos(coords);
    }

    // マイタウン表示
    mytownShow() {
      this.fetchMachiRepos({});
    }

    // 現在位置表示
    currentLocationShow() {
      // ブラウザに現在地取得機能があるか確認
      if (!navigator.geolocation) {
        alert('ブラウザに現在地取得機能がありません');
        return;
      }

      // 現在地の取得
      navigator.geolocation.getCurrentPosition(position => {
        const coords = {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        };

        this.fetchMachiRepos(coords);
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
    searchLocationShow() {
      let address = { address: this.searchTarget.value };
      this.fetchMachiRepos(address);
    }

    // まちレポ情報の取得とマップ関連表示更新
    fetchMachiRepos(data) {
      fetch(`/machi_repos/fetch_machi_repos`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify(data)
      })
      .then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html))
      .catch(error => {
        console.error("まちレポ取得失敗:", error)
      });
    }
}
