export function loadGoogleMaps(apiKey) {
  return new Promise((resolve, reject) => {
    if (window.google && window.google.maps) {
      // console.log("Google Maps API already loaded.");
      resolve(window.google.maps);
      return;
    }

    // console.log("Loading Google Maps API...");
    const script = document.createElement("script");
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&callback=initGoogleMaps&loading=async`;
    script.async = true;
    script.defer = true;
    script.onerror = () => reject(new Error("Google Maps API could not load."));

    window.initGoogleMaps = () => resolve(window.google.maps);
    document.head.appendChild(script);
  });
}
