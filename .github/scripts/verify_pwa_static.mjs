// Verifica que el build web conserve los requisitos de una PWA instalable.
// Uso: BASE_HREF=/repo/ node .github/scripts/verify_pwa_static.mjs build/web
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const webDir = process.argv[2] ?? 'build/web';
const baseHref = process.env.BASE_HREF ?? '/';
const errors = [];
const check = (ok, message) => { if (!ok) errors.push(message); };
const read = (file) => readFileSync(join(webDir, file), 'utf8');

function pngSize(file) {
  const buf = readFileSync(join(webDir, file));
  if (buf.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a') return null;
  return `${buf.readUInt32BE(16)}x${buf.readUInt32BE(20)}`;
}

// 1. Manifest
let manifest = {};
try {
  manifest = JSON.parse(read('manifest.json'));
} catch (e) {
  errors.push(`manifest.json no es JSON válido: ${e.message}`);
}
for (const field of ['name', 'short_name', 'start_url', 'display', 'icons', 'theme_color', 'background_color']) {
  check(manifest[field], `manifest.json no tiene "${field}"`);
}
check(['standalone', 'fullscreen', 'minimal-ui'].includes(manifest.display),
  `display "${manifest.display}" no permite instalar la app`);

const anySizes = new Set();
for (const icon of manifest.icons ?? []) {
  if (!existsSync(join(webDir, icon.src))) {
    errors.push(`no existe el ícono ${icon.src}`);
    continue;
  }
  const size = pngSize(icon.src);
  check(size !== null, `${icon.src} no es un PNG`);
  check(size === icon.sizes, `${icon.src} mide ${size}, el manifest dice ${icon.sizes}`);
  if (!icon.purpose || icon.purpose.split(' ').includes('any')) anySizes.add(icon.sizes);
}
check(anySizes.has('192x192'), 'falta un ícono "any" de 192x192');
check(anySizes.has('512x512'), 'falta un ícono "any" de 512x512');

// 2. index.html
const html = read('index.html');
check(html.includes(`<base href="${baseHref}">`), `index.html no tiene <base href="${baseHref}">`);
check(!html.includes('$FLUTTER_BASE_HREF'), 'index.html conserva $FLUTTER_BASE_HREF sin reemplazar');
check(/rel="manifest"/.test(html), 'index.html no enlaza el manifest');
check(/<html lang="es">/.test(html), 'index.html no declara lang="es"');
check(/serviceWorker\.register\(\s*['"]sw\.js/.test(html), 'index.html no registra sw.js');

// 3. Service worker propio
if (existsSync(join(webDir, 'sw.js'))) {
  const sw = read('sw.js');
  check(sw.includes("addEventListener('fetch'"), 'sw.js no intercepta peticiones (fetch)');
  check(!sw.includes('__BUILD_VERSION__'), 'sw.js no tiene la versión del build');
} else {
  errors.push('no existe sw.js');
}

// 4. El bootstrap no debe registrar el service worker de Flutter (se desregistra solo).
const bootstrap = read('flutter_bootstrap.js').trimEnd();
check(/_flutter\.loader\.load\(\s*\);?$/.test(bootstrap),
  'flutter_bootstrap.js debe terminar con _flutter.loader.load() sin serviceWorkerSettings');

// 5. Recursos servidos desde el mismo origen (necesario para funcionar offline).
for (const file of ['main.dart.js', 'canvaskit/canvaskit.wasm']) {
  check(existsSync(join(webDir, file)), `no existe ${file} (¿falta --no-web-resources-cdn?)`);
}

if (errors.length) {
  console.error('PWA (estructura) con errores:\n' + errors.map((e) => ` - ${e}`).join('\n'));
  process.exit(1);
}
console.log('PWA (estructura) OK');
