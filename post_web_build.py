import os
import time
import re
import shutil

workspace_dir = os.path.dirname(os.path.abspath(__file__))
exports_dir = os.path.join(workspace_dir, "exports")
timestamp = int(time.time())

ruby_icon_src = os.path.join(workspace_dir, "assets", "ruby.png")
bg_src = os.path.join(workspace_dir, "assets", "bg_ref.jpg")

def generate_assets(target_dir, file_prefix):
    # 1. Generate icons
    png_path = os.path.join(target_dir, f"{file_prefix}.png")
    apple_path = os.path.join(target_dir, f"{file_prefix}.apple-touch-icon.png")
    icon_path = os.path.join(target_dir, f"{file_prefix}.icon.png")
    
    if os.path.exists(ruby_icon_src):
        print(f"Generating web icons for {file_prefix} in {target_dir}...")
        os.system(f'sips -z 512 512 "{ruby_icon_src}" --out "{png_path}" >/dev/null 2>&1')
        os.system(f'sips -z 180 180 "{ruby_icon_src}" --out "{apple_path}" >/dev/null 2>&1')
        os.system(f'sips -z 256 256 "{ruby_icon_src}" --out "{icon_path}" >/dev/null 2>&1')

    # 2. Copy background image
    if os.path.exists(bg_src):
        bg_dest = os.path.join(target_dir, "game_bg.jpg")
        shutil.copy(bg_src, bg_dest)
        print(f"Copied game_bg.jpg background to {target_dir}")

# 1. Setup exports/web (Vercel Build)
web_dir = os.path.join(exports_dir, "web")
if os.path.exists(web_dir):
    # Generate assets first
    generate_assets(web_dir, "game")

    # manifest.json
    manifest_content = """{
  "name": "ranotot",
  "short_name": "ranotot",
  "description": "Hop on your scooter and become the galaxy's craziest delivery driver!",
  "start_url": ".",
  "display": "fullscreen",
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
  './game_bg.jpg',
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

        # Clean up any previously injected service worker registration scripts
        html = re.sub(r'<script>\s*if\s*\(\s*\'serviceWorker\'\s*in\s*navigator\s*\)[\s\S]*?</script>\s*', '', html, flags=re.IGNORECASE)

        # Add service worker registration script if not exists (checked via sw.js)
        if 'sw.js' not in html:
            sw_register = """    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('./sw.js')
                    .then((reg) => {
                        console.log('Service Worker registered successfully:', reg.scope);
                        reg.addEventListener('updatefound', () => {
                            const newWorker = reg.installing;
                            newWorker.addEventListener('statechange', () => {
                                if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                                    console.log('New update installed. Clearing client caches and reloading...');
                                    if (window.caches) {
                                        caches.keys().then((names) => {
                                            Promise.all(names.map(name => caches.delete(name))).then(() => {
                                                window.location.reload();
                                            });
                                        }).catch(() => {
                                            window.location.reload();
                                        });
                                    } else {
                                        window.location.reload();
                                    }
                                }
                            });
                        });
                    })
                    .catch((err) => console.error('Service Worker registration failed:', err));
            });
        }
    </script>\n</head>"""
            html = re.sub(r'\s*</head>', '\n' + sw_register, html, flags=re.IGNORECASE)

        # Focus the game frame whenever the user clicks/touches the parent window (for gamepads/controllers)
        if 'gameFrame' in html and 'resumeAudioContexts' not in html:
            focus_helper = """        // Focus the game frame whenever the user clicks/touches the parent window
        window.addEventListener('click', () => {
            var frame = document.getElementById('gameFrame');
            if (frame) { 
                frame.focus(); 
                if (navigator.vibrate) { navigator.vibrate(20); }
                try {
                    if (frame.contentWindow && frame.contentWindow.resumeAudioContexts) {
                        frame.contentWindow.resumeAudioContexts();
                    }
                } catch(e) {}
            }
        });
        window.addEventListener('touchstart', () => {
            var frame = document.getElementById('gameFrame');
            if (frame) { 
                frame.focus(); 
                if (navigator.vibrate) { navigator.vibrate(20); }
                try {
                    if (frame.contentWindow && frame.contentWindow.resumeAudioContexts) {
                        frame.contentWindow.resumeAudioContexts();
                    }
                } catch(e) {}
            }
        });
        window.addEventListener('DOMContentLoaded', () => {
            var frame = document.getElementById('gameFrame');
            if (frame) {
                frame.focus();
                frame.addEventListener('load', () => { frame.focus(); });
            }
            if (navigator.storage && navigator.storage.persist) {
                navigator.storage.persist().then((persisted) => {
                    console.log('Persistent storage status:', persisted);
                });
            }
        });
        
        // Initial setup
        resizeIframe();"""
            if "// Initial setup\n        resizeIframe();" in html:
                html = html.replace("// Initial setup\n        resizeIframe();", focus_helper)
            elif "resizeIframe();" in html:
                html = html.replace("resizeIframe();", focus_helper)

        # Allow vibrate inside the iframe
        if 'gameFrame' in html and 'vibrate' not in html:
            html = html.replace('allow="autoplay; fullscreen; xr-spatial-tracking; gamepad"', 'allow="autoplay; fullscreen; xr-spatial-tracking; gamepad; vibrate"')

        with open(index_path, "w") as f:
            f.write(html)

    # game.html scaling and loading screen background modification
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
            html = re.sub(r'html,\s*body,\s*#canvas\s*\{[^}]*\}', new_style, html, flags=re.IGNORECASE)

        # Inject game background into HTML loading screen (#status background)
        old_status_bg = """#status {
	background-color: #242424;"""
        new_status_bg = """#status {
	background-image: url('game_bg.jpg');
	background-size: cover;
	background-position: center;
	background-repeat: no-repeat;"""
        if old_status_bg in html:
            html = html.replace(old_status_bg, new_status_bg)
        else:
            html = re.sub(r'#status\s*\{\s*background-color:\s*#242424;', new_status_bg, html, flags=re.IGNORECASE)

        # Clean up any previously injected canvas focus/vibrate scripts to prevent duplicate/stale tags
        html = re.sub(r'<script>\s*window\.addEventListener\(\'click\',\s*\(\)\s*=>\s*\{\s*var\s+canvas\s*=\s*document\.getElementById\(\'canvas\'\);[\s\S]*?</script>\s*', '', html, flags=re.IGNORECASE)
        html = re.sub(r'<script>\s*\(function\(\)\s*\{\s*window\._audioContexts[\s\S]*?</script>\s*', '', html, flags=re.IGNORECASE)

        # Inject AudioContext constructor hook right after <head>
        if 'window._audioContexts' not in html:
            audio_hook = """<head>
    <script>
        (function() {
            window._audioContexts = [];
            const OriginalAudioContext = window.AudioContext || window.webkitAudioContext;
            if (OriginalAudioContext) {
                const HookedAudioContext = function(...args) {
                    const ctx = new OriginalAudioContext(...args);
                    window._audioContexts.push(ctx);
                    return ctx;
                };
                HookedAudioContext.prototype = OriginalAudioContext.prototype;
                if (window.AudioContext) { window.AudioContext = HookedAudioContext; }
                if (window.webkitAudioContext) { window.webkitAudioContext = HookedAudioContext; }
            }
            window.resumeAudioContexts = function() {
                if (window._audioContexts) {
                    window._audioContexts.forEach(ctx => {
                        if (ctx && ctx.state === 'suspended') {
                            ctx.resume().then(() => {
                                console.log('AudioContext resumed successfully.');
                            }).catch(err => {
                                console.warn('Failed to resume AudioContext:', err);
                            });
                        }
                    });
                }
            };
            window.addEventListener('click', window.resumeAudioContexts);
            window.addEventListener('touchstart', window.resumeAudioContexts);
            window.addEventListener('keydown', window.resumeAudioContexts);
        })();
    </script>"""
            html = re.sub(r'<head>', audio_hook, html, flags=re.IGNORECASE)

        # Inject click/touchstart canvas focus logic
        if 'canvas.focus()' not in html:
            focus_script = """<script>
    window.addEventListener('click', () => {
        var canvas = document.getElementById('canvas');
        if (canvas) { 
            canvas.focus(); 
            if (navigator.vibrate) { navigator.vibrate(20); }
        }
        if (window.resumeAudioContexts) { window.resumeAudioContexts(); }
    });
    window.addEventListener('touchstart', () => {
        var canvas = document.getElementById('canvas');
        if (canvas) { 
            canvas.focus(); 
            if (navigator.vibrate) { navigator.vibrate(20); }
        }
        if (window.resumeAudioContexts) { window.resumeAudioContexts(); }
    });
    if (navigator.storage && navigator.storage.persist) {
        navigator.storage.persist().then((persisted) => {
            console.log('Persistent storage status:', persisted);
        });
    }
</script>\n</body>"""
            html = re.sub(r'</body>', focus_script, html, flags=re.IGNORECASE)

        with open(game_path, "w") as f:
            f.write(html)

    print(f"PWA & Fullscreen scaling configured for exports/web (version: {timestamp})")

# 2. Setup exports/ranotot_Web (Direct Build)
direct_dir = os.path.join(exports_dir, "ranotot_Web")
if os.path.exists(direct_dir):
    # Generate assets first
    generate_assets(direct_dir, "index")

    # manifest.json
    manifest_content = """{
  "name": "ranotot",
  "short_name": "ranotot",
  "description": "Hop on your scooter and become the galaxy's craziest delivery driver!",
  "start_url": ".",
  "display": "fullscreen",
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
  './game_bg.jpg',
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

        # Clean up any previously injected service worker registration scripts
        html = re.sub(r'<script>\s*if\s*\(\s*\'serviceWorker\'\s*in\s*navigator\s*\)[\s\S]*?</script>\s*', '', html, flags=re.IGNORECASE)

        # Add service worker registration script if not exists (checked via sw.js)
        if 'sw.js' not in html:
            sw_register = """    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('./sw.js')
                    .then((reg) => {
                        console.log('Service Worker registered successfully:', reg.scope);
                        reg.addEventListener('updatefound', () => {
                            const newWorker = reg.installing;
                            newWorker.addEventListener('statechange', () => {
                                if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                                    console.log('New update installed. Clearing client caches and reloading...');
                                    if (window.caches) {
                                        caches.keys().then((names) => {
                                            Promise.all(names.map(name => caches.delete(name))).then(() => {
                                                window.location.reload();
                                            });
                                        }).catch(() => {
                                            window.location.reload();
                                        });
                                    } else {
                                        window.location.reload();
                                    }
                                }
                            });
                        });
                    })
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
            html = re.sub(r'html,\s*body,\s*#canvas\s*\{[^}]*\}', new_style, html, flags=re.IGNORECASE)

        # Inject game background into HTML loading screen (#status background)
        old_status_bg = """#status {
	background-color: #242424;"""
        new_status_bg = """#status {
	background-image: url('game_bg.jpg');
	background-size: cover;
	background-position: center;
	background-repeat: no-repeat;"""
        if old_status_bg in html:
            html = html.replace(old_status_bg, new_status_bg)
        else:
            html = re.sub(r'#status\s*\{\s*background-color:\s*#242424;', new_status_bg, html, flags=re.IGNORECASE)

        # Clean up any previously injected canvas focus/vibrate scripts to prevent duplicate/stale tags
        html = re.sub(r'<script>\s*window\.addEventListener\(\'click\',\s*\(\)\s*=>\s*\{\s*var\s+canvas\s*=\s*document\.getElementById\(\'canvas\'\);[\s\S]*?</script>\s*', '', html, flags=re.IGNORECASE)
        html = re.sub(r'<script>\s*\(function\(\)\s*\{\s*window\._audioContexts[\s\S]*?</script>\s*', '', html, flags=re.IGNORECASE)

        # Inject AudioContext constructor hook right after <head>
        if 'window._audioContexts' not in html:
            audio_hook = """<head>
    <script>
        (function() {
            window._audioContexts = [];
            const OriginalAudioContext = window.AudioContext || window.webkitAudioContext;
            if (OriginalAudioContext) {
                const HookedAudioContext = function(...args) {
                    const ctx = new OriginalAudioContext(...args);
                    window._audioContexts.push(ctx);
                    return ctx;
                };
                HookedAudioContext.prototype = OriginalAudioContext.prototype;
                if (window.AudioContext) { window.AudioContext = HookedAudioContext; }
                if (window.webkitAudioContext) { window.webkitAudioContext = HookedAudioContext; }
            }
            window.resumeAudioContexts = function() {
                if (window._audioContexts) {
                    window._audioContexts.forEach(ctx => {
                        if (ctx && ctx.state === 'suspended') {
                            ctx.resume().then(() => {
                                console.log('AudioContext resumed successfully.');
                            }).catch(err => {
                                console.warn('Failed to resume AudioContext:', err);
                            });
                        }
                    });
                }
            };
            window.addEventListener('click', window.resumeAudioContexts);
            window.addEventListener('touchstart', window.resumeAudioContexts);
            window.addEventListener('keydown', window.resumeAudioContexts);
        })();
    </script>"""
            html = re.sub(r'<head>', audio_hook, html, flags=re.IGNORECASE)

        # Inject click/touchstart canvas focus logic
        if 'canvas.focus()' not in html:
            focus_script = """<script>
    window.addEventListener('click', () => {
        var canvas = document.getElementById('canvas');
        if (canvas) { 
            canvas.focus(); 
            if (navigator.vibrate) { navigator.vibrate(20); }
        }
        if (window.resumeAudioContexts) { window.resumeAudioContexts(); }
    });
    window.addEventListener('touchstart', () => {
        var canvas = document.getElementById('canvas');
        if (canvas) { 
            canvas.focus(); 
            if (navigator.vibrate) { navigator.vibrate(20); }
        }
        if (window.resumeAudioContexts) { window.resumeAudioContexts(); }
    });
    if (navigator.storage && navigator.storage.persist) {
        navigator.storage.persist().then((persisted) => {
            console.log('Persistent storage status:', persisted);
        });
    }
</script>\n</body>"""
            html = re.sub(r'</body>', focus_script, html, flags=re.IGNORECASE)

        with open(index_path, "w") as f:
            f.write(html)
        print(f"PWA & Fullscreen scaling configured for exports/ranotot_Web (version: {timestamp})")
