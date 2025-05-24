export function createCustomInfoWindowClass() {
  return class CustomInfoWindow extends google.maps.OverlayView {
    constructor(infoWindowElements, marker, machiRepo) {
      super();
      // infoWindow用のテンプレートHTML
      this.infoWindowElements = infoWindowElements;
      // AdvancedMarkerElementオブジェクト
      this.marker = marker;
      // マーカーの座標(google.maps.LatLngオブジェクト)
      this.position = new google.maps.LatLng(marker.position.lat, marker.position.lng);
      // まちレポデータ(user、profile結合)
      this.machiRepo = machiRepo;
      this.div = null;
    }

    onAdd() {
      this.div = document.createElement("div");
      this.div.style.position = "absolute";
      this.div.appendChild(this.infoWindowElements);
      const link = this.div.querySelector(".info-window-link");
      link.href = `/machi_repos/${this.machiRepo.id}`;
      this.div.querySelector(".info-window-title").textContent = `${this.machiRepo.title}`;
      this.div.querySelector(".info-window-user").textContent = `${this.machiRepo.user.profile.nickname}`;
      this.div.querySelector(".info-window-address").textContent = `${this.machiRepo.address}`;
      const panes = this.getPanes();
      panes.floatPane.appendChild(this.div);

      // InfoWindowを閉じる
      this.div.querySelector(".info-window-close").addEventListener("click", () => {
        this.setMap(null);
      });

      // タッチイベント時にInfoWindowを表示すると同時に遷移してしまう現象の対策
      link.style.pointerEvents = "none";
      setTimeout(() => {
        link.style.pointerEvents = "auto";
      }, 300);
    }

    draw() {
      const projection = this.getProjection();
      const point = projection.fromLatLngToDivPixel(this.position);
      if (point && this.div) {
        const divWidth = this.div.offsetWidth;
        const divHeight = this.div.offsetHeight;

        const offsetX = -divWidth / 2;  // 横中央揃え
        const offsetY = -divHeight - (this.marker.offsetHeight + 10); // マーカーの上に配置するため高さ分上にずらす

        this.div.style.left = `${point.x + offsetX}px`;
        this.div.style.top = `${point.y + offsetY}px`;
      }
    }

    onRemove() {
      if (this.div) {
        this.div.remove();
        this.div = null;
      }
    }
  }
}