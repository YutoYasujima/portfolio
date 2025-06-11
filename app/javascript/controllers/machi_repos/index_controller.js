import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps } from "../../lib/google_maps_utils";
import { createCustomInfoWindowClass } from "../../lib/custom_info_window";

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
      "infoWindowWrapper",
      "machiRepoCards",
      "scrollableIcon",
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
      // 開かれているInfoWindowの管理
      this.currentInfoWindow = null;
      // マイタウンの緯度・経度を保持
      this.defaultCoordinates = { lat: this.latitudeValue, lng: this.longitudeValue };
      // input[type="hidden"]に値を保持
      this.hiddenAddressTarget.value = this.addressValue;
      this.hiddenLatitudeTarget.value = this.latitudeValue;
      this.hiddenLongitudeTarget.value = this.longitudeValue;
      // Googleマップのzoomを取得
      this.defaultZoom = Number(localStorage.getItem("mapZoom")) || 14;
      // 検索フォームの開閉状態設定
      if (localStorage.getItem("searchWindowOpen")) {
        // 検索フォームを開く
        this.searchFormWrapperTarget.classList.remove("invisible-element");
      } else {
        this.searchFormWrapperTarget.classList.add("invisible-element");
      }
      this.toggleSearchFormWindow();
      // 無限スクロールフラグ
      this.loading = false;
      // 無限スクロールページ数
      this.currentPage = 1;
      // 無限スクロールの要否判定
      const lastPageMarker = document.getElementById("machi-repo-last-page-marker");
      const isLastPage = lastPageMarker?.dataset.lastPage === "true";
      if (!isLastPage) {
        window.addEventListener("scroll", this.onScroll);
        this.scrollableIconTarget.classList.remove("hidden");
      }

      // Googleマップの導入
      loadGoogleMaps(this.apiKeyValue).then(() => this.initMap());
    }

    // 無限スクロール用トリガー
    onScroll = () => {
      const rect = this.machiRepoCardsTarget.getBoundingClientRect();
      if (rect.bottom <= window.innerHeight + 300) {
        this.loadPreviousPage();
      }
    }

    // 無限スクロール
    loadPreviousPage() {
      if (this.loading) {
        return;
      }
      this.loading = true;
      this.currentPage++;

      // 検索フォームの各値を取得
      const params = new URLSearchParams();
      params.append("page", this.currentPage);
      const topId = document.getElementById("machi-repos-top-id");
      params.append("top_id", topId.dataset.topId);
      params.append("search[title]", this.inputTitleTarget.value);
      params.append("search[info_level]", this.inputInfoLevelTarget.value);
      params.append("search[category]", this.inputCategoryTarget.value);
      params.append("search[tag_names]", this.inputTagNamesTarget.value);
      params.append("search[tag_match_type]", this.inputTagMatchTypeOrTarget.checked ? "or" : "and");
      params.append("search[start_date]", this.inputStartDateTarget.value);
      params.append("search[end_date]", this.inputEndDateTarget.value);
      params.append("search[latitude]", this.hiddenLatitudeTarget.value);
      params.append("search[longitude]", this.hiddenLongitudeTarget.value);
      params.append("search[address]", this.hiddenAddressTarget.value);

      const url = `/machi_repos/load_more?${params.toString()}`;
      // 次のページ（上方向）を非同期で取得
      fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html"
        }
      })
      .then(response => response.text())
      .then(html => {
        // Turbo Streamの中身を表示する
        Turbo.renderStreamMessage(html);
        // Turbo StreamのHTMLが挿入された後にDOMを見る
        requestAnimationFrame(() => {
          const lastPageMarker = document.getElementById("machi-repos-last-page-marker");
          const isLastPage = lastPageMarker?.dataset.lastPage === "true";
          if (isLastPage) {
            window.removeEventListener("scroll", this.onScroll);
            this.scrollableIconTarget.classList.add("hidden");
          }
          this.loading = false;
        });
      });
    }

    disconnect() {
      // Googleマップのzoomを保持
      localStorage.setItem("mapZoom", this.map.getZoom());
      // メモリへの影響を考慮し解放しておく
      // マーカー解放
      this.clearMarkers();
      // 表示中のInfoWindow解放
      if (this.currentInfoWindow) {
        this.currentInfoWindow.setMap(null);
        this.currentInfoWindow = null;
      }

      // Googleマップのイベントリスナ－解放
      if (this.mainMarkerDragendListener) {
        this.mainMarkerDragendListener.remove();
        this.mainMarkerDragendListener = null;
      }

      this.map = null;

      window.removeEventListener("scroll", this.onScroll);
    }

    // マーカーをすべて解放する
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
        scale: 1.2,
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
      this.mainMarkerDragendListener = this.mainMarker.addListener("dragend", () => this.onDragendMarker());
      // disconnect時にクリアするためマーカーを保持する
      this.markers.push(this.mainMarker);
    }

    // 周辺のまちレポマーカー表示
    async createMachiRepoMarkers() {
      const { AdvancedMarkerElement, PinElement } = await google.maps.importLibrary("marker");
      // カスタムInfoWindowクラス呼び出し
      const CustomInfoWindow = createCustomInfoWindowClass();
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
        const infoWindowTemplate = this.infoWindowWrapperTarget.children[0].cloneNode(true);
        const infoWindow = new CustomInfoWindow(infoWindowTemplate, marker, machiRepo);

        // マーカークリックでInfoWindow表示
        marker.addEventListener("gmp-click", () => {
          if (this.currentInfoWindow) {
            // 開かれているInfoWindowを閉じる
            this.currentInfoWindow.setMap(null);
          }
          // InfoWindow表示
          infoWindow.setMap(this.map);
          // InfoWindowの表示が全部見えるようにマップを移動
          this.map.panTo(marker.position);
          this.map.panBy(0, -80);
          this.currentInfoWindow = infoWindow;
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

    // 検索フォームのヘッダークリックイベントリスナー
    onClickSearchFormWindow() {
      this.searchFormWrapperTarget.classList.toggle("invisible-element");
      // 検索フォームの開閉処理
      this.toggleSearchFormWindow();
    }

    // 検索フォームの開閉処理
    toggleSearchFormWindow() {
      // 検索フォームの開閉状態をローカルストレージ保持しておく
      if (this.searchFormWrapperTarget.classList.contains("invisible-element")) {
        // 検索フォームが閉じているとき
        this.addIconTarget.classList.remove("hidden");
        this.removeIconTarget.classList.add("hidden");
        // 閉じているときは値を保持しない
        // 取得時にnull(falsy)になるため
        localStorage.removeItem("searchWindowOpen");
      } else {
        // 検索フォームが開いているとき
        this.addIconTarget.classList.add("hidden");
        this.removeIconTarget.classList.remove("hidden");
        // 開いているときは保持する
        localStorage.setItem("searchWindowOpen", true);
      }
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
