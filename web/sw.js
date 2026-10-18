'use strict';

// El workflow de CI reemplaza __BUILD_VERSION__ en build/web/sw.js por el
// commit, así cada despliegue crea una caché nueva y borra la anterior.
const VERSION = '__BUILD_VERSION__';
const CACHE = `puzzle15-${VERSION}`;

// Rutas relativas a sw.js: funcionan con cualquier --base-href.
const PRECACHE = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
];

// Recursos externos versionados (fuente Roboto que descarga Flutter web).
const CDN_HOSTS = ['fonts.gstatic.com', 'www.gstatic.com'];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // allSettled: si algún archivo no existe en esta versión de Flutter,
    // el resto se guarda igual y la instalación no falla.
    await Promise.allSettled(
      PRECACHE.map((url) => cache.add(new Request(url, { cache: 'reload' }))),
    );
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(
      keys
        .filter((key) => key.startsWith('puzzle15-') && key !== CACHE)
        .map((key) => caches.delete(key)),
    );
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin === self.location.origin) {
    event.respondWith(networkFirst(request));
  } else if (CDN_HOSTS.includes(url.hostname)) {
    event.respondWith(cacheFirst(request));
  }
});

// Primero la red (siempre la versión más nueva); la caché solo sin conexión.
async function networkFirst(request) {
  const cache = await caches.open(CACHE);
  try {
    const response = await fetch(request);
    if (response.status === 200) {
      cache.put(request, response.clone()).catch(() => {});
    }
    return response;
  } catch (error) {
    const cached = await cache.match(request, { ignoreSearch: true });
    if (cached) return cached;
    if (request.mode === 'navigate') {
      const shell = (await cache.match('index.html')) ?? (await cache.match('./'));
      if (shell) return shell;
    }
    throw error;
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response.status === 200 || response.type === 'opaque') {
    cache.put(request, response.clone()).catch(() => {});
  }
  return response;
}
