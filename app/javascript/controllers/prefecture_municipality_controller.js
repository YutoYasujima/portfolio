import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="prefecture-municipality"
export default class extends Controller {
  static targets = [ "municipality" ];

  connect() {
  }

  // 都道府県選択時に、市区町村の選択肢を変える
  async loadMunicipalities(event) {
    // 都道府県セレクトボックスの選択値
    const prefectureId = event.target.value;
    const response = await fetch(`/municipalities?prefecture_id=${prefectureId})`);
    const data = await response.json();

    // 市区町村セレクトボックスの作成
    this.municipalityTarget.innerHTML = "";
    data.forEach(municipality => {
      const option = document.createElement('option');
      option.value = municipality.id;
      option.textContent = municipality.name_kanji;
      this.municipalityTarget.appendChild(option);
    });
  }
}
