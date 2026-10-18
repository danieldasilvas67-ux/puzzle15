{{flutter_js}}
{{flutter_build_config}}

// Se arranca sin serviceWorkerSettings: el service worker que genera Flutter
// en las versiones actuales solo se desregistra a sí mismo y reemplazaría al
// propio. El soporte offline lo da web/sw.js (registrado en index.html).
_flutter.loader.load();
