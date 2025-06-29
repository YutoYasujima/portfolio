export function loadGoogleMaps(apiKey) {
  return new Promise((resolve, reject) => {
    if (window.google && window.google.maps) {
      resolve(window.google.maps);
      return;
    }

    const script = document.createElement("script");
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&callback=initGoogleMaps&loading=async`;
    script.async = true;
    script.defer = true;
    script.onerror = () => reject(new Error("Google Maps API could not load."));

    window.initGoogleMaps = () => resolve(window.google.maps);
    document.head.appendChild(script);
  });
}

// クライアントでジオコーディング
export function geocoding(address) {
  return new Promise((resolve, reject) => {
    // ジオコーディング
    new google.maps.Geocoder().geocode({ address: address },
    (results, status) => { // resultは変換結果、statusは処理の状況
      // ジオコーディング失敗
      if (status !== 'OK' || !results[0]) {
        console.error("ジオコーディング失敗:", status);
        reject({ error: "geocode_failed" });
        return;
      }

      const result = results[0];
      const components = result.address_components;

      // 日本以外
      const country = components.find(c => c.types.includes("country"));
      if (!country || country.short_name !== "JP") {
        console.error("日本の住所ではありません");
        reject({ error: "not_japan" });
        return;
      }

      const prefecture = components.find(c => c.types.includes("administrative_area_level_1"));
      const city = components.find(c => c.types.includes("locality") || c.types.includes("administrative_area_level_2"));

      // 都道府県・市区町村取得失敗
      if (!prefecture || !city) {
        console.error("都道府県または市区町村が特定できませんでした");
        reject({ error: "missing_prefecture_or_city" });
        return;
      }

      const formattedAddress = getAddressFromGeocodeResult(result);
      const location = result.geometry.location;

      resolve({ lat: location.lat(), lng: location.lng(), address: formattedAddress });

      // if (status === 'OK' && results[0]) {
      //   const formattedAddress = getAddressFromGeocodeResult(results[0]);
      //   const location = results[0].geometry.location;
      //   resolve({ lat: location.lat(), lng: location.lng(), address: formattedAddress });
      // } else {
      //   console.error("ジオコーディング失敗:", status);
      //   reject(null);
      // }
    });
  });
}

// クライアントでリバースジオコーディング
export function reverseGeocoding(coordinates) {
  return new Promise((resolve, reject) => {
    // リバースジオコーディング
    new google.maps.Geocoder().geocode({ location: coordinates },
      (results, status) => {
      if (status === "OK" && results[0]) {
        const formattedAddress = getAddressFromGeocodeResult(results[0]);
        const location = results[0].geometry.location;
        resolve({ lat: location.lat(), lng: location.lng(), address: formattedAddress });
      } else {
        console.error("リバースジオコーディング失敗:", status);
        reject(null);
      }
    });
  });
}

// Googleマップのgeocode機能の処理結果から表示用住所を取得
function getAddressFromGeocodeResult(result) {
  const components = result.address_components;

  const prefectureComponent = components.find(c =>
    c.types.includes("administrative_area_level_1")
  );
  const cityComponent = components.find(c =>
    c.types.includes("locality") ||
    c.types.includes("administrative_area_level_2") ||
    c.types.includes("sublocality_level_1")
  );

  const prefecture = prefectureComponent ? prefectureComponent.long_name : "";
  const city = cityComponent ? cityComponent.long_name : "";

  return `${prefecture}${city}`;

  // const components = result.address_components;
  // let prefecture = "";
  // let city = "";
  // components.forEach(component => {
  //   if (component.types.includes("administrative_area_level_1")) {
  //     prefecture = component.long_name;
  //   }
  //   if (component.types.includes("locality")) {
  //     city = component.long_name;
  //   }
  // });
  // return `${prefecture}${city}`;
}
