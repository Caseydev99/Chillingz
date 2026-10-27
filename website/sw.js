/* ==========================================================================
   sw.js — the "service worker": lets the site work on a bad connection
   --------------------------------------------------------------------------
   A service worker is a small script the browser keeps running in the
   background. This one:
     • saves a copy of the main files (styles, scripts, logo) the first time
       someone visits, so the site opens faster next time
     • keeps a copy of each page and photo as people browse
     • when there's no internet, shows the saved copy — or the friendly
       offline.html page if that page was never visited
   It always tries the internet first for pages, scripts and listings, so
   people see the latest version whenever they're online.

   When you change the website, nothing needs doing here: copies refresh by
   themselves. Only change CACHE_VERSION if you want to throw away every
   saved copy at once.
   ========================================================================== */

const CACHE_VERSION = "v1";
const CACHE_NAME = `chillingz-${CACHE_VERSION}`;

// Saved straight away on the first visit
const CORE_FILES = [
  "./",
  "index.html",
  "offline.html",
  "css/styles.css",
  "js/site.js",
  "js/data.js",
  "js/utils.js",
  "js/auth.js",
  "js/favourites.js",
  "js/firebase.js",
  "js/newsletter.js",
  "js/content.js",
  "js/cards.js",
  "js/home.js",
  "images/logo.png",
  "images/logo.webp",
  "images/favicon.png",
];

/* First visit: save the core files. */
self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(CORE_FILES)).then(() => self.skipWaiting()),
  );
});

/* New version: delete old saved copies. */
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) => Promise.all(names.filter((name) => name.startsWith("chillingz-") && name !== CACHE_NAME).map((name) => caches.delete(name))))
      .then(() => self.clients.claim()),
  );
});

/* Internet first; if that fails, use the saved copy. Saves what it gets. */
async function networkFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  try {
    const response = await fetch(request);
    if (response.ok) cache.put(request, response.clone());
    return response;
  } catch {
    const saved = await cache.match(request, { ignoreSearch: request.mode === "navigate" });
    if (saved) return saved;
    if (request.mode === "navigate") return cache.match("offline.html");
    throw new Error("Offline and not saved");
  }
}

/* Photos rarely change: use the saved copy if there is one. */
async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const saved = await cache.match(request);
  if (saved) return saved;
  const response = await fetch(request);
  if (response.ok) cache.put(request, response.clone());
  return response;
}

self.addEventListener("fetch", (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Only handle this website's own files. Leave alone: other websites
  // (Firebase, Google Fonts, maps), anything that isn't a plain "get",
  // and the Flutter app in /app/, which has its own service worker.
  if (request.method !== "GET" || url.origin !== self.location.origin) return;
  const scopePath = new URL(self.registration.scope).pathname;
  if (url.pathname.startsWith(`${scopePath}app/`)) return;

  if (url.pathname.includes("/images/")) {
    event.respondWith(cacheFirst(request));
  } else {
    event.respondWith(networkFirst(request));
  }
});
