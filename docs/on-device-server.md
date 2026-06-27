# On-device lute-v3 server

LuteForMobile can run a Lute v3 server directly on your Android phone, with
no Termux, no separate install, and no need for a separate computer.

## What it does

A small on-device card in **Settings → Server** lets you download a
~15–25 MB tarball from this repo's GitHub Releases. The app extracts it
into its private storage, and at your command starts the lute-v3
Python server inside a regular OS process on `127.0.0.1:<chosen port>`.
The rest of the app then talks to it over the same HTTP JSON contract
it would use for a remote Lute v3 server.

## Trade-offs vs. Remote mode

| | Remote | On-device | Termux |
|---|---|---|---|
| Needs network | yes (after first sync) | no | no |
| Needs another app installed | no | no | yes (Termux) |
| Setup time | URL in settings | one-time download | multi-step |
| Startup time | depends on host | ~3–5 s | ~10–30 s |
| Java (MeCab) parsing | host side | **not bundled** | if installed |
| Data ownership | remote host | on device | on device |
| Backup portability | host export | `.lute3` (same as desktop) | `.lute3` |

**Japanese is the one big caveat:** MeCab is not bundled in the
on-device build. If you read Japanese books, use Remote mode against a
host that has MeCab set up.

## How data flows

```
GitHub Releases
  └── lute-server-v3.10.1/
       └── lute-server-android-arm64-v3.10.1.tar.gz
            └── downloaded by the app, SHA256 verified
                 └── extracted to:
                      <app-private-files>/lute-server/3.10.1/
                           ├── python/    (CPython 3.11 runtime)
                           ├── lute-deps/ (Flask, SQLAlchemy, etc.)
                           ├── lute/      (the lute-v3 package)
                           └── lute-server (launcher script)
                                 │
                                 ▼  ProcessBuilder
            <app-private-files>/lute/lute.db  (lute v3 SQLite)
                                 │
                                 ▼
                       ApiService  ──  http://127.0.0.1:<port>/
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

- **On Android 10 and below**: same path; the app's requestLegacyExternalStorage
  setting is for other features and is unrelated to this one.

## Updating the on-device server

The on-device server is pinned to a specific lute-v3 version at build
time (currently `3.10.1`). When upstream releases a new lute-v3
version, a new `lute-server` artifact will be published to GitHub
Releases. The app's "Updates" button in the on-device card checks
GitHub and tells you when a new artifact is available.

To upgrade: tap **Remove** in the on-device card, then **Download**
again. Your data is preserved (the `lute/lute.db` file is in a
separate directory from the server artifact).

There is no automatic upgrade. This is intentional — for a
local-first feature, silent upgrades are a footgun.

## Build process (developer notes)

The lute-server artifact is released **independently** of the app
because it has its own release cadence — it tracks upstream
`LuteOrg/lute-v3` releases, not changes to the Flutter app.

```bash
# Build the lute-server artifact for a specific lute-v3 version, publish
# it to GitHub Releases, and update Settings.luteServerPinnedVersion to
# match so the next app build picks it up.
scripts/release_lute_server.sh 3.11.0

# Build + publish the Flutter app (APK + PWA).
scripts/release_app.sh 1.3.0
```

Under the hood `release_lute_server.sh` calls:

1. `scripts/build_lute_server.sh <ver>` — checks out
   `LuteOrg/lute-v3` at the pinned tag, builds a relocatable
   CPython 3.11 runtime targeting `aarch64-linux-android` (using
   the `quay.io/pypa/manylinux2014_aarch64` Docker image), and
   packages lute-v3 + its deps into a single tarball.
2. Updates `Settings.luteServerPinnedVersion` in
   `lib/features/settings/models/settings.dart` to match the lute
   version, so the next app build looks for the right tag.
3. `scripts/publish_lute_server.sh <ver>` — publishes the tarball
   + a SHA256 sidecar to a `lute-server-v<ver>` GitHub release in
   `schlick7/LuteForMobile`.

The legacy `new_release.sh` is kept as a shim that prints a
deprecation notice and forwards to `release_app.sh`. It will be
removed in a future release.

## Limitations (v1)

- **No MeCab Japanese.** Use Remote mode for Japanese.
- **No auto-restart on app cold start.** The on-device server starts
  when the user explicitly taps Start, or when `main.dart` re-runs
  (next app launch) and the artifact is already installed.
- **arm64 only.** Devices on 32-bit Android (rare in 2025) cannot
  run the on-device server. Use Remote mode.
- **No foreground service.** The OS may kill the server if the app
  is backgrounded for a long time. Reopening the app restarts it.
- **No custom plugins.** The Python `entry_points`-based plugin
  system from upstream lute-v3 is not supported in the embedded
  build; only the bundled parsers (space-delimited, classical
  Chinese, Turkish).
- **No iOS.** iOS does not allow executing downloaded binaries. The
  on-device option is hidden on iOS; the PWA remains the iOS path.
