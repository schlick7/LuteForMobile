'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"manifest.json": "6f7d3004218e6b29c4a4a6a74df4eb08",
"main.dart.js": "7bba470564a6995b14f836d20b6c171b",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"index.html": "7c1b153caefea2b3985cc1692e0ebde4",
"/": "7c1b153caefea2b3985cc1692e0ebde4",
"flutter_bootstrap.js": "9a3be65623eb4e8085bef171dbcce871",
"version.json": "eebcd7f61bbd8a04d48e41e95ab6a59a",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"assets/NOTICES": "c1cb55ba7d3fc43845f6881d1e1d1800",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "509ae636cfdd93e49b5a6eaf0f06d79f",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/AssetManifest.bin.json": "6c19a0bf060d63f59d33b9fea1767903",
"assets/AssetManifest.bin": "e426f012ff324a29b6b923bb93c79049",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/FontManifest.json": "dbb50870c1a4e20d55c88f54967743f0",
"assets/fonts/MaterialIcons-Regular.otf": "9cd8e06017eebac9560cc54be8d1c23d",
"assets/assets/fonts/literata/Literata-Bold.ttf": "a7299a35b91fecbdf536cf8dd5f5b0a5",
"assets/assets/fonts/literata/Literata-SemiBold.ttf": "78bf5e69ec6938f28d24af119aa95083",
"assets/assets/fonts/literata/Literata-BoldItalic.ttf": "779a92ac45ab7bce8cd4a2189d482ecb",
"assets/assets/fonts/literata/Literata-MediumItalic.ttf": "8e4ad44c0554ac9b26f54e6e8d53a092",
"assets/assets/fonts/literata/Literata-SemiBoldItalic.ttf": "03a8519f38ba720a4e7fe862b5711a17",
"assets/assets/fonts/literata/Literata-Italic.ttf": "b27baaa0d7d8b39916c7e895b7ee765e",
"assets/assets/fonts/literata/Literata-Medium.ttf": "c1320e4ad34941482400572ad68a0a80",
"assets/assets/fonts/literata/Literata-Regular.ttf": "996ada098d06289615fd00aede9d6e8b",
"assets/assets/fonts/VollkornPS/Vollkorn-Italic.otf": "7b726e6369ee5630e2928aa5b34d2154",
"assets/assets/fonts/VollkornPS/Vollkorn-BlackItalic.otf": "48aa8308f37f3bab5c1fc9277d6ecb00",
"assets/assets/fonts/VollkornPS/Vollkorn-Black.otf": "f1e6c42df28b57736e334aee88e938b7",
"assets/assets/fonts/VollkornPS/Vollkorn-MediumItalic.otf": "954785f3c666fbab209f603e55417ab5",
"assets/assets/fonts/VollkornPS/Vollkorn-BoldItalic.otf": "111db9d7a31febd45ac0bb50a2052414",
"assets/assets/fonts/VollkornPS/Vollkorn-Regular.otf": "2a74db36878fd191bb3c2f4c6575a19f",
"assets/assets/fonts/VollkornPS/Vollkorn-SemiBold.otf": "a622652ce1a1c1dd55b22faf8f6e45cc",
"assets/assets/fonts/VollkornPS/Vollkorn-SemiBoldItalic.otf": "1ba0f517d03dfb1d20548d957386cb2d",
"assets/assets/fonts/VollkornPS/Vollkorn-Bold.otf": "83467cfa4400474b6d068d7d268da90e",
"assets/assets/fonts/VollkornPS/Vollkorn-Medium.otf": "30d0352bfef2ef7ce4b9b9994f38fc8a",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-RegularItalic.otf": "86264040044d2894ac32fa3ed74b9429",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Medium.otf": "0ae63804fda9539f0c897e1c889f24ec",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-SemiBold.otf": "d1708ed7f49dbf22aef47da7b7ad4a06",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-ExtraLight.otf": "9fd48c148321ec25cfb0c6e8ac856952",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-ExtraBold.otf": "5623fc3eb35434fe33e08fc460d59ecd",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-BoldItalic.otf": "72e47131880f8b7c4d18c179d44e580a",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-SemiBoldItalic.otf": "752134a093ba3e5f9f7c8649cb878768",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-LightItalic.otf": "986e4154a747f5b1052a1a91e2b6c10f",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-ExtraLightItalic.otf": "f75b6530a076fcace1916eb34adec33f",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-MediumItalic.otf": "80b41617321d773666834a80ac003f18",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Light.otf": "9a29dc71df69872784fd4ea61b38a0d7",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Bold.otf": "68d75570f78c06e7b7f4a9e1336407c9",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-Regular.otf": "91b877d542114f17b40002351bfdfc3c",
"assets/assets/fonts/AtkinsonHyperlegibleNext/AtkinsonHyperlegibleNext-ExtraBoldItalic.otf": "de508eaa15c1af10df183b81c849fcb0",
"assets/assets/fonts/linux-biolinum/LinBiolinum_R.otf": "d0073c4d7149ec31d8ebf8eea691743c",
"assets/assets/fonts/linux-biolinum/LinBiolinum_RI.otf": "f1a3c5609d4f5f9a27c8bce71638b0ae",
"assets/assets/fonts/linux-biolinum/LinBiolinum_RB.otf": "c3192f41093de33ae234ef7872acd5bd"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
