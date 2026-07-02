import os
import time
import re

workspace_dir = os.path.dirname(os.path.abspath(__file__))
exports_dir = os.path.join(workspace_dir, "exports")
timestamp = int(time.time())

# 1. Setup exports/web (Vercel Build)
web_dir = os.path.join(exports_dir, "web")
if os.path.exists(web_dir):
    # manifest.json
    manifest_content = """{
  "name": "ranotot",
  "short_name": "ranotot",
  "description": "Hop on your scooter and become the galaxy's craziest delivery driver!",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#000000",
  "theme_color": "#000000",
  "orientation": "landscape",
  "icons": [
    {
      "src": "game.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "game.icon.png",
      "sizes": "256x256",
      "type": "image/png"
    },
    {
      "src": "game.apple-touch-icon.png",
      "sizes": "180x180",
      "type": "image/png"
    }
  ]
}"""
    with open(os.path.join(web_dir, "manifest.json"), "w") as f:
        f.write(manifest_content)

    # sw.js
    sw_content = """const CACHE_NAME = 'ranotot-vercel-cache-v__VERSION__';
const ASSETS = [
  './',
  './index.html',
  './game.html',
  './game.js',
  './game.wasm',
  './game.pck',
  './game.audio.worklet.js',
  './game.audio.position.worklet.js',
  './game.icon.png',
  './game.apple-touch-icon.png',
  './game.png',
  './manifest.json'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        return Promise.all(
          ASSETS.map((asset) => {
            return cache.add(asset).catch((err) => {
              console.warn(`[Service Worker Vercel] Failed to cache asset: ${asset}`, err);
            });
          })
        );
      })
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cache) => {
          if (cache !== CACHE_NAME) {
            console.log('[Service Worker Vercel] Deleting old cache:', cache);
            return caches.delete(cache);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      return fetch(event.request).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200) {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      }).catch((err) => {
        console.error('[Service Worker Vercel] Fetch failed:', err);
      });
    })
  );
});
""".replace('__VERSION__', str(timestamp))

    with open(os.path.join(web_dir, "sw.js"), "w") as f:
        f.write(sw_content)

    # index.html modification (Ensure PWA heads and SW registration exist)
    index_path = os.path.join(web_dir, "index.html")
    if os.path.exists(index_path):
        with open(index_path, "r") as f:
            html = f.read()

        # Add manifest link if not exists
        if 'rel="manifest"' not in html:
            html = re.sub(r'\s*<head>', '<head>\n    <link rel="manifest" href="manifest.json">\n    <meta name="apple-mobile-web-app-capable" content="yes">\n    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">\n    <link rel="apple-touch-icon" href="game.apple-touch-icon.png">', html, flags=re.IGNORECASE)

        # Add service worker registration script if not exists (checked via sw.js)
        if 'sw.js' not in html:
            sw_register = """    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('./sw.js')
                    .then((reg) => console.log('Service Worker registered successfully:', reg.scope))
                    .catch((err) => console.error('Service Worker registration failed:', err));
            });
        }
    </script>\n</head>"""
            html = re.sub(r'\s*</head>', '\n' + sw_register, html, flags=re.IGNORECASE)

        with open(index_path, "w") as f:
            f.write(html)

    # game.html scaling modification (Ensure full viewport scaling)
    game_path = os.path.join(web_dir, "game.html")
    if os.path.exists(game_path):
        with open(game_path, "r") as f:
            html = f.read()

        # Force full screen sizing on html, body, and canvas
        old_style = """html, body, #canvas {
	margin: 0;
	padding: 0;
	border: 0;
}"""
        new_style = """html, body, #canvas {
	margin: 0;
	padding: 0;
	border: 0;
	width: 100%;
	height: 100%;
	overflow: hidden;
}"""
        if old_style in html:
            html = html.replace(old_style, new_style)
        else:
            # Fallback regex if formatting differs slightly
            html = re.sub(r'html,\s*body,\s*#canvas\s*\{[^}]*\}', new_style, html, flags=re.IGNORECASE)

        with open(game_path, "w") as f:
            f.write(html)

    print(f"PWA & Fullscreen scaling configured for exports/web (version: {timestamp})")

# 2. Setup exports/ranotot_Web (Direct Build)
direct_dir = os.path.join(exports_dir, "ranotot_Web")
if os.path.exists(direct_dir):
    # manifest.json
    manifest_content = """{
  "name": "ranotot",
  "short_name": "ranotot",
  "description": "Hop on your scooter and become the galaxy's craziest delivery driver!",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#000000",
  "theme_color": "#000000",
  "orientation": "landscape",
  "icons": [
    {
      "src": "index.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "index.icon.png",
      "sizes": "256x256",
      "type": "image/png"
    },
    {
      "src": "index.apple-touch-icon.png",
      "sizes": "180x180",
      "type": "image/png"
    }
  ]
}"""
    with open(os.path.join(direct_dir, "manifest.json"), "w") as f:
        f.write(manifest_content)

    # sw.js
    sw_content = """const CACHE_NAME = 'ranotot-direct-cache-v__VERSION__';
const ASSETS = [
  './',
  './index.html',
  './index.js',
  './index.wasm',
  './index.pck',
  './index.audio.worklet.js',
  './index.audio.position.worklet.js',
  './index.icon.png',
  './index.apple-touch-icon.png',
  './index.png',
  './manifest.json'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        return Promise.all(
          ASSETS.map((asset) => {
            return cache.add(asset).catch((err) => {
              console.warn(`[Service Worker Direct] Failed to cache asset: ${asset}`, err);
            });
          })
        );
      })
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cache) => {
          if (cache !== CACHE_NAME) {
            console.log('[Service Worker Direct] Deleting old cache:', cache);
            return caches.delete(cache);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      return fetch(event.request).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200) {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      }).catch((err) => {
        console.error('[Service Worker Direct] Fetch failed:', err);
      });
    })
  );
});
""".replace('__VERSION__', str(timestamp))

    with open(os.path.join(direct_dir, "sw.js"), "w") as f:
        f.write(sw_content)

    # index.html modification (Direct export HTML is completely overwritten by Godot)
    index_path = os.path.join(direct_dir, "index.html")
    if os.path.exists(index_path):
        with open(index_path, "r") as f:
            html = f.read()

        # Add manifest link if not exists
        if 'rel="manifest"' not in html:
            html = re.sub(r'\s*<head>', '<head>\n    <link rel="manifest" href="manifest.json">\n    <meta name="apple-mobile-web-app-capable" content="yes">\n    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">\n    <link rel="apple-touch-icon" href="index.apple-touch-icon.png">', html, flags=re.IGNORECASE)

        # Add service worker registration script if not exists (checked via sw.js)
        if 'sw.js' not in html:
            sw_register = """    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('./sw.js')
                    .then((reg) => console.log('Service Worker registered successfully:', reg.scope))
                    .catch((err) => console.error('Service Worker registration failed:', err));
            });
        }
    </script>\n</head>"""
            html = re.sub(r'\s*</head>', '\n' + sw_register, html, flags=re.IGNORECASE)

        # Force full screen sizing on html, body, and canvas
        old_style = """html, body, #canvas {
	margin: 0;
	padding: 0;
	border: 0;
}"""
        new_style = """html, body, #canvas {
	margin: 0;
	padding: 0;
	border: 0;
	width: 100%;
	height: 100%;
	overflow: hidden;
}"""
        if old_style in html:
            html = html.replace(old_style, new_style)
        else:
            # Fallback regex if formatting differs slightly
            html = re.sub(r'html,\s*body,\s*#canvas\s*\{[^}]*\}', new_style, html, flags=re.IGNORECASE)

        with open(index_path, "w") as f:
            f.write(html)
        print(f"PWA & Fullscreen scaling configured for exports/ranotot_Web (version: {timestamp})")
