// Abre el build en Chromium, comprueba que Chrome lo considera instalable y que
// vuelve a arrancar sin conexión gracias al service worker.
// Uso: BASE_HREF=/repo/ node .github/scripts/verify_pwa_offline.mjs build/web
import { createServer } from 'node:http';
import { mkdtemp, readFile, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { extname, join, resolve, sep } from 'node:path';
import { chromium } from 'playwright';

const webDir = resolve(process.argv[2] ?? 'build/web');
const baseHref = process.env.BASE_HREF ?? '/';
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.ico': 'image/x-icon',
  '.css': 'text/css',
  '.svg': 'image/svg+xml',
};

// Servidor estático que imita GitHub Pages bajo el prefijo BASE_HREF.
const server = createServer(async (req, res) => {
  try {
    const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (!path.startsWith(baseHref)) throw new Error('fuera del prefijo');
    let file = resolve(webDir, '.' + sep + path.slice(baseHref.length));
    if (file !== webDir && !file.startsWith(webDir + sep)) throw new Error('ruta inválida');
    if ((await stat(file)).isDirectory()) file = join(file, 'index.html');
    const body = await readFile(file);
    res.writeHead(200, {
      'Content-Type': MIME[extname(file)] ?? 'application/octet-stream',
      'Cache-Control': 'no-cache',
    });
    res.end(body);
  } catch {
    res.writeHead(404);
    res.end();
  }
});
await new Promise((ok) => server.listen(0, '127.0.0.1', ok));
const appUrl = `http://127.0.0.1:${server.address().port}${baseHref}`;

const context = await chromium.launchPersistentContext(
  await mkdtemp(join(tmpdir(), 'pwa-')),
  { headless: true, channel: process.env.PW_CHANNEL || 'chromium' },
);

const waitFirstFrame = (page, timeout) =>
  page.waitForFunction(() => window.__primerFrame === true, null, { timeout });

try {
  await context.addInitScript(() => {
    window.__primerFrame = false;
    window.addEventListener('flutter-first-frame', () => { window.__primerFrame = true; });
  });
  const page = context.pages()[0] ?? (await context.newPage());

  // 1. Primera visita: arranca la app y se instala el service worker.
  await page.goto(appUrl);
  await waitFirstFrame(page, 90_000);
  await page.evaluate(() => navigator.serviceWorker.ready);

  // 2. Chrome la considera instalable.
  const cdp = await context.newCDPSession(page);
  const { installabilityErrors } = await cdp.send('Page.getInstallabilityErrors');
  if (installabilityErrors.length) {
    throw new Error('No instalable: ' + installabilityErrors.map((e) => e.errorId).join(', '));
  }
  const { errors: manifestErrors } = await cdp.send('Page.getAppManifest');
  if (manifestErrors.length) {
    throw new Error('Manifest con errores: ' + manifestErrors.map((e) => e.message).join(', '));
  }

  // 3. Segunda visita en línea: ya pasa por el service worker y llena la caché.
  await page.reload();
  await waitFirstFrame(page, 90_000);
  const controlled = await page.evaluate(() => navigator.serviceWorker.controller !== null);
  if (!controlled) throw new Error('El service worker no controla la página');

  // 4. Sin conexión: se apaga el servidor y la red del navegador.
  server.closeAllConnections();
  await new Promise((ok) => server.close(ok));
  await context.setOffline(true);
  await page.reload();
  await waitFirstFrame(page, 30_000);

  console.log('PWA OK: instalable y arranca sin conexión');
} catch (error) {
  console.error('PWA con errores:', error.message);
  process.exitCode = 1;
} finally {
  await context.close();
  if (server.listening) server.close();
}
