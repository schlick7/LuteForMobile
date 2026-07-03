# On-device lute-v3 server

LuteForMobile can run a Lute v3 server directly on your Android phone, with
no Termux, no separate install, and no need for a separate computer.

## What it does

The lute-v3 Python server source is **bundled into the APK** at build time
(under `android/app/src/main/python/lute/`) and invoked at runtime via
[Chaquopy](https://chaquo.com/chaquopy/). A card in **Settings → Server**
on Android lets the user start the server inside the app process; once it's
up, the rest of the app talks to it over `http://127.0.0.1:<chosen port>/`
using the same HTTP JSON contract a remote Lute v3 server would expose.

The on-device server is currently hidden on iOS and on web (PWA still works
there; see [`README.md`](../README.md)).

## Trade-offs vs. Remote mode

| | Remote | On-device | Termux |
|---|---|---|---|
| Needs network | yes (after first sync) | no | no |
| Needs another app installed | no | no | yes (Termux) |
| Setup time | URL in settings | none — bundled in APK | multi-step |
| Startup time | depends on host | ~3–5 s | ~10–30 s |
| Java (MeCab) parsing | host side | **not bundled** | if installed |
| Data ownership | remote host | on device | on device |
| Backup portability | host export | `.lute3` (same as desktop) | `.lute3` |

**Japanese is the one big caveat:** MeCab is not bundled in the
on-device build. If you read Japanese books, use Remote mode against a
host that has MeCab set up.

## How data flows

```
android/app/src/main/python/        (bundled in APK)
  ├── lute/        ← lute-v3 Python package, compiled by Chaquopy
  ├── bridge.py    ← thin Python<->Kotlin fs helper
  └── launcher.py  ← entry point the Kotlin bridge calls
                       │
                       ▼  Chaquopy call
  lute.main.start(...)  →  Flask app
       │
       ▼  listens on
  http://127.0.0.1:<ephemeral port>/
       │
       ▼
  ApiService  ──  same HTTP JSON contract as a remote Lute v3 server
```

The `.lute.db` file is byte-compatible with the desktop Lute v3 server.
You can:

- Use the app's built-in backup feature to export a `.lute3` file.
- Copy that file to a PC and restore it in the desktop Lute v3 server.
- Conversely, take a desktop Lute v3 `lute.db`, drop it in
  `<app-private-files>/lute/lute.db`, and the on-device server will
  pick it up on next start.

## Storage locations

- **On Android 11+** (scoped storage): the app's private files dir,
  usually `/data/data/com.schlick7.luteformobile/files/`. Hidden from
  the user file manager; backed up to your Google account if the app
  participates in Android Backup.

- **On Android 10 and below**: same path; the app's `requestLegacyExternalStorage`
  setting is for other features and is unrelated to this one.

## Updating the on-device server

The on-device server is part of the app: changing it means changing the
bundled `android/app/src/main/python/lute/` tree and rebuilding the APK.
There is no in-app "update" button for the server.

## Source of the bundled `lute/` tree

LuteForMobile does not track `LuteOrg/lute-v3` directly. The bundled
tree is taken from **`https://github.com/schlick7/lute-v3` at the
`fullstats` branch** at the time the APK is built. The in-app About
page (`lute/templates/version.html`) and the Dart pin
(`Settings.luteServerPinnedVersion` in
`lib/features/settings/models/settings.dart`) are kept in sync.

> **For maintainers:** the bundled tree in
> `android/app/src/main/python/lute/` must **not** be edited by hand.
> To update, re-apply the overlay from the fork (see [Build process](#build-process-developer-notes))
> and re-verify that the two Android-specific patches survived the swap:
>
> 1. `lute/bridge.py` — thin Python<->Kotlin helper. **Not in the
>    upstream fork**; we add it so the backup flow can use the
>    main-process SELinux context to write image files.
> 2. `lute/app_factory.py` — the `required_dirs` block forces the
>    `backups/` directory to mode `0o755`. Chaquopy's Python defaults
>    to umask `0o077`, which would otherwise break `shutil.copytree`.
> 3. `lute/backup/service.py` — replaces the `os.mkdir` +
>    `shutil.copytree` sequence with a call to `bridge.mirror_images_from_kotlin`,
>    for the same SELinux reason.
>
> `lute/db/language_defs/*` is also inlined in the repo (not a git
> submodule) and must be preserved across an overlay. The overlay
> command in the next section excludes both `bridge.py` and
> `db/language_defs/`.

## Build process (developer notes)

### Updating the bundled lute-v3 source

```bash
# 1. Snapshot the Android-specific files we have to keep.
mkdir -p /tmp/lute-preserve
cp android/app/src/main/python/lute/bridge.py                          /tmp/lute-preserve/
cp android/app/src/main/python/lute/app_factory.py                    /tmp/lute-preserve/app_factory.py.android-patched
cp android/app/src/main/python/lute/backup/service.py                 /tmp/lute-preserve/service.py.android-patched
cp -r android/app/src/main/python/lute/db/language_defs               /tmp/lute-preserve/language_defs

# 2. Clone the fork and overlay the lute/ tree.
rm -rf /tmp/lute-v3-fullstats
git clone --depth 1 --branch fullstats https://github.com/schlick7/lute-v3.git /tmp/lute-v3-fullstats
rsync -a --delete \
  --exclude='bridge.py' \
  --exclude='db/language_defs/' \
  /tmp/lute-v3-fullstats/lute/ \
  android/app/src/main/python/lute/

# 3. Restore the Android-specific files.
cp /tmp/lute-preserve/bridge.py                                            android/app/src/main/python/lute/bridge.py
cp /tmp/lute-preserve/app_factory.py.android-patched                       android/app/src/main/python/lute/app_factory.py
cp /tmp/lute-preserve/service.py.android-patched                           android/app/src/main/python/lute/backup/service.py
rsync -a /tmp/lute-preserve/language_defs/                                 android/app/src/main/python/lute/db/language_defs/

# 4. Bump the version pin (Python + Dart, both must match).
$EDITOR android/app/src/main/python/lute/__init__.py        # __version__ = "<x.y.z-foo>"
$EDITOR lib/features/settings/models/settings.dart         # luteServerPinnedVersion = '<x.y.z-foo>'

# 5. Sanity check.
diff -rq /tmp/lute-v3-fullstats/lute android/app/src/main/python/lute
# Expected output: only the three files we patched
# (app_factory.py, backup/service.py, version.html) and — by design —
# the language_defs/ tree and bridge.py which are not in the fork.
```

### App release

```bash
# Build + publish the Flutter app (APK + PWA).
scripts/release_app.sh 1.3.0
```

The legacy `new_release.sh` is kept as a shim that prints a
deprecation notice and forwards to `release_app.sh`. It will be
removed in a future release. There is **no separate server-tarball
release step** — the server is in the APK.

## Limitations (v1)

- **No MeCab Japanese.** Use Remote mode for Japanese.
- **No auto-restart on app cold start.** The on-device server starts
  when the user explicitly taps Start, or when `main.dart` re-runs
  (next app launch) and the server is configured to auto-start.
- **arm64 + x86_64 only** (see `abiFilters` in
  `android/app/build.gradle.kts`). Devices on 32-bit Android (rare in
  2025) cannot run the on-device server. Use Remote mode.
- **No foreground service.** The OS may kill the server if the app
  is backgrounded for a long time. Reopening the app restarts it.
- **No custom plugins.** The Python `entry_points`-based plugin
  system from upstream lute-v3 is not supported in the embedded
  build; only the bundled parsers (space-delimited, classical
  Chinese, Turkish).
- **No iOS.** iOS does not allow executing downloaded binaries. The
  on-device option is hidden on iOS; the PWA remains the iOS path.
