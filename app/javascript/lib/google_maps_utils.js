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
      if (status === 'OK' && results[0]) {
        const formattedAddress = getAddressFromGeocodeResult(results[0]);
        const location = results[0].geometry.location;
        resolve({ lat: location.lat(), lng: location.lng(), address: formattedAddress });
      } else {
        console.warn("ジオコーディング失敗:", status);
        reject(null);
      }
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
        console.warn("リバースジオコーディング失敗:", status);
        reject(null);
      }
    });
  });
}

// Googleマップのgeocode機能の処理結果から表示用住所を取得
function getAddressFromGeocodeResult(result) {
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
