export const environment = {
  production: false,
  apiBaseUrl: 'http://localhost:8000/api',
  // Keyless tile sources; swap for a keyed provider when one is provisioned.
  mapTileUrl: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
  satelliteTileUrl:
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  // Society fence for boundary drawing: "minLng,minLat,maxLng,maxLat".
  societyBbox: '90.3000,23.7800,90.3470,23.8380',
};
