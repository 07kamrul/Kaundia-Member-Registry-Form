import * as L from 'leaflet';

// Geoman references the global `L`, which ESM bundles don't provide.
// This must be evaluated before '@geoman-io/leaflet-geoman-free'.
(globalThis as unknown as { L: typeof L }).L = L;
