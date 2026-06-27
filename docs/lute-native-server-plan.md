# Lute on-device server: implementation plan (final)

## Goal

Add an "On-device" server option to LuteForMobile (Android only) that
runs the Lute v3 Python server in-process — no Termux, no side-install.
The default is still "Remote" (talk to `serverUrl`); the user opts in
by downloading the on-device server binary from your existing GitHub
Releases.

- **Default app state:** `localServerMode = remote`. No bundled server,
  no extra download, APK stays small.
- **User opts in:** Settings → Server → "On-device" → Download →
  Start. Once running, `ApiService.baseUrl` flips to
  `http://127.0.0.1:<port>/`. The Termux path stays as a third
  option, untouched.
- **Data is 100% interchangeable** with the desktop Lute v3 server
  (same SQLite file, same schema, same column names, same ZWS
  token-join semantics, same `get_lowercase` rules, same
  `wordparents` M2M). User can copy `lute.db` to a PC, open it in
  desktop Lute; and vice versa.
- **No MeCab for Japanese in v1.** Japanese is marked "use remote
  for Japanese" in the UI, same as today's situation when a user
  hasn't installed MeCab in Termux. Defer until a user actually
  needs it.

---

## Decisions locked in

| | |
|---|---|
| Default | `localServerMode = remote` |
| Opt-in download | tarball from `schlick7/LuteForMobile` GitHub Releases, tag `lute-server-v<lute_version>` |
| Build tool | **Chaquopy** for the embedded Python (less CI friction, well-trodden) |
| Architectures | arm64 only (covers >98% of active Android devices) |
| iOS | On-device option hidden. PWA remains the iOS story. |
| Termux path | Kept behind `localServerMode == termux`. No removal in this release. |
| Updates | Manual "Check for update" button. No background checks. |
| Compat pin | App has a hardcoded `LUTE_SERVER_VERSION` (e.g. `"3.10.1"`) that the download URL is built from. |
| Integrity | SHA256 sidecar file fetched with the tarball, verified before extraction. |
| Storage | `getApplicationSupportDirectory()/lute-server/<version>/` — hidden from user file manager. |
| DB | `getApplicationSupportDirectory()/lute/lute.db` — same `.lute3` backup format as today, byte-compatible. |
| Build host | Local machine, no GitHub Actions. `new_release.sh` extended with a `lute-server` step. |

---

## How the build chain works

```
┌──────────────────────────┐
│ upstream: LuteOrg/lute-v3│  (git tag 3.10.1, plain Python)
└────────────┬─────────────┘
             │ (developer runs scripts/build_lute_server.sh locally)
             ▼
┌──────────────────────────┐
│ android/app/src/main/    │
│   python/lute/  (copy)   │  Chaquopy gradle plugin packages
│ + stdlib + waitness      │  these into the embedded runtime
└────────────┬─────────────┘
             │ ./gradlew bundleChaquopy
             ▼
┌──────────────────────────┐
│ dist/lute-server-arm64   │  ~15-25 MB tarball
│ .tar.gz                  │
└────────────┬─────────────┘
             │ gh release create lute-server-v3.10.1 ...
             ▼
┌──────────────────────────┐
│ schlick7/LuteForMobile   │
│ Release: lute-server-    │
│ v3.10.1                  │
└──────────────────────────┘
             │ (user taps "Download" in app)
             ▼
┌──────────────────────────┐
│ /data/data/<pkg>/files/  │
│   lute-server/3.10.1/    │  installed artifact
└──────────────────────────┘
             │ (user taps "Start")
             ▼
┌──────────────────────────┐
│ ProcessBuilder           │  python -m lute.main --port N
│ python -m lute.main      │  --datapath <appfiles>/lute
│ --port N --datapath ...  │  --local
└──────────────────────────┘
```

---

## File-by-file changes

### New files

| Path | LOC (est.) | Purpose |
|---|---|---|
| `lib/core/services/embedded_server_service.dart` | ~400 | Dart API: download, start, stop, remove, update, getState, getPort, getVersion. EventChannel for download progress. |
| `lib/features/settings/widgets/on_device_server_section.dart` | ~250 | Settings UI: download button, progress bar, installed version, start/stop, remove, check for update. |
| `lib/core/services/lute_server_manifest.dart` | ~30 | `LUTE_SERVER_VERSION`, `LUTE_SERVER_BASE_URL`, build download URL, parse GitHub releases. |
| `android/app/src/main/kotlin/com/schlick7/luteformobile/EmbeddedServerBridge.kt` | ~280 | MethodChannel handler. Manages artifact dir, download, extract, hash verify, process lifecycle. |
| `android/app/src/main/kotlin/com/schlick7/luteformobile/EmbeddedServerProcess.kt` | ~120 | Process spawn, port picker, health poll (`GET /info` 200), SIGTERM/SIGKILL, log capture. |
| `android/app/build.gradle` (delta) | ~40 | Chaquopy plugin block, `python { ... }` source set, packaging excludes. |
| `android/app/src/main/python/launcher.py` | ~20 | Thin wrapper that calls `lute.main:start()` with android-friendly defaults. |
| `android/app/proguard-chaquopy.pro` | ~30 | Keep rules for Python reflection. |
| `scripts/build_lute_server.sh` | ~80 | Local build: check out `LuteOrg/lute-v3` at pinned tag, run `./gradlew bundleChaquopy`, copy artifact, write `sha256sum`. |
| `scripts/publish_lute_server.sh` | ~60 | Wraps `gh release create lute-server-v<ver>` with the tarball + sha256. |
| `scripts/check_chaquopy_license.sh` | ~20 | Build-time sanity that Chaquopy's CPython license is bundled in app's third-party-licenses screen. |
| `docs/on-device-server.md` | ~200 | User-facing doc: how to switch to on-device, where data lives, how to back up the DB, how to update the server. |

### Modified files

| Path | Change |
|---|---|
| `pubspec.yaml` | Bump nothing; no new Dart deps needed (using `package:archive` already transitive, or add it explicitly). |
| `lib/features/settings/models/settings.dart` | Add `LocalServerMode` enum. Add `localServerMode` field. Add `embeddedServerVersionInstalled`. Replace `termuxIntegrationEnabled`. |
| `lib/main.dart` | On startup, if `localServerMode == onDevice`, call `EmbeddedServerService.instance.ensureStarted()`. If `localServerMode == termux`, call existing `TermuxService.startServer()`. No change for `remote`. |
| `lib/core/network/api_service.dart` | No change. It already builds baseUrl from a `Settings.termuxUrl` or `Settings.serverUrl`; we just feed it the right one. |
| `lib/core/services/termux_service.dart` | Keep class, but rename exposed methods to make the seam obvious. `termux_service.dart` becomes the dispatcher that calls either `EmbeddedServerService` or the existing Termux MethodChannel based on `localServerMode`. |
| `lib/features/settings/screens/settings_screen.dart` | Replace the "Termux Integration" toggle with the three-way radio. |
| `lib/shared/providers/server_status_provider.dart` | Subscribe to `EmbeddedServerService.events` instead of (or in addition to) the Termux heartbeat. |
| `android/app/src/main/AndroidManifest.xml` | Add `INTERNET` (already there) and `WAKE_LOCK` (optional, for background reads). |
| `android/app/src/main/kotlin/com/schlick7/luteformobile/MainActivity.kt` | Register the new MethodChannel. |
| `new_release.sh` | Add optional step that calls `scripts/publish_lute_server.sh` if `--with-server` flag is passed. |
| `README.md` | Document the new "On-device" option. |
| `docs/luteendpoints.md` | No change (we're implementing existing endpoints). |
| `docs/PWA_SETUP_GUIDE.md` | No change. |

### Removed (or dead-coded) in this release

Nothing removed. The Termux path stays. We can deprecate `TermuxBridge.kt` etc. in a follow-up release once `onDevice` has been stable for a few months.

---

## Public APIs

### Dart → Kotlin (MethodChannel `com.schlick7.luteformobile/embedded_server`)

```dart
class EmbeddedServerService {
  static EmbeddedServerService get instance;

  /// Latest version we know about (from GitHub). null if not yet checked.
  Future<ServerManifest?> checkForUpdate();

  /// Download the pinned LUTE_SERVER_VERSION. Emits progress on event channel.
  Future<DownloadResult> download({void Function(double progress)? onProgress});

  /// Cancel an in-flight download.
  Future<void> cancelDownload();

  /// Start the installed server. Returns the URL it's serving on.
  Future<String> start();

  /// Stop the running server. Idempotent.
  Future<void> stop();

  /// Remove the installed artifact. Server must be stopped first.
  Future<void> remove();

  /// Current state: notInstalled | downloading | ready | starting | running | error
  Future<EmbeddedServerState> getState();

  /// Currently bound port, if running.
  Future<int?> getPort();
}

enum EmbeddedServerState { notInstalled, downloading, ready, starting, running, error }
```

### Kotlin → Dart (EventChannel `com.schlick7.luteformobile/embedded_server_progress`)

```kotlin
sealed class EmbeddedServerEvent {
  data class DownloadProgress(val bytesDone: Long, val bytesTotal: Long) : EmbeddedServerEvent()
  data class Started(val port: Int) : EmbeddedServerEvent()
  data class Stopped(val exitCode: Int) : EmbeddedServerEvent()
  data class LogLine(val line: String) : EmbeddedServerEvent()
  data class Error(val message: String) : EmbeddedServerEvent()
}
```

### Settings shape (Dart)

```dart
enum LocalServerMode { remote, onDevice, termux }

class Settings {
  // existing fields...
  final LocalServerMode localServerMode;
  final String? embeddedServerInstalledVersion;  // null if not installed
  final String embeddedServerPinnedVersion;       // const, e.g. "3.10.1"
  // ...
}
```

`Settings.termuxUrl` becomes a derived getter: returns
`http://127.0.0.1:<embeddedPort>/` when `localServerMode == onDevice`
and the server is running, otherwise the existing Termux behavior,
otherwise null. `ApiService` keeps consuming the same getter.

---

## Settings UI (mock)

```
┌─────────────────────────────────────┐
│ Server                              │
├─────────────────────────────────────┤
│  ◯  Remote                          │
│      Server URL: [http://10.0.0.5  ]│
│      [Test connection]              │
│                                     │
│  ◉  On-device                       │
│      ┌───────────────────────────┐  │
│      │ Lute server v3.10.1       │  │
│      │ Not installed             │  │
│      │ ~18 MB download           │  │
│      │ [Download]                │  │
│      └───────────────────────────┘  │
│                                     │
│  ◯  Termux (advanced)               │
│      [Open Termux setup]            │
└─────────────────────────────────────┘
```

After download, the card becomes:

```
┌─────────────────────────────────────┐
│ Lute server v3.10.1                 │
│ Installed · 18.3 MB                 │
│                                     │
│ [Start]   [Check for update]        │
│                                     │
│ Remove server                       │
└─────────────────────────────────────┘
```

After start, it becomes:

```
┌─────────────────────────────────────┐
│ Lute server v3.10.1                 │
│ Running on http://127.0.0.1:51234/  │
│                                     │
│ [Stop]    [View logs]               │
│                                     │
│ Restart on app launch: [on]         │
└─────────────────────────────────────┘
```

The "On-device" card shows a yellow "⚠ Japanese requires remote server" notice — not blocking, just informational.

---

## Build script: `scripts/build_lute_server.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

LUTE_VERSION="${1:-3.10.1}"   # default pin, override with arg
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${REPO_ROOT}/build/lute-server"
ARTIFACT_DIR="${REPO_ROOT}/dist"

echo "==> Cloning LuteOrg/lute-v3 at tag ${LUTE_VERSION}"
rm -rf "${BUILD_DIR}"
git clone --depth 1 --branch "${LUTE_VERSION}" \
  https://github.com/LuteOrg/lute-v3.git "${BUILD_DIR}"

echo "==> Building arm64 artifact via Chaquopy"
cd "${REPO_ROOT}/android"
./gradlew :app:bundleChaquopy \
  -PchaquopyPythonVersion=3.11 \
  -PchaquopyAbi=arm64-v8a

echo "==> Assembling tarball"
mkdir -p "${ARTIFACT_DIR}"
OUT="${ARTIFACT_DIR}/lute-server-android-arm64-v${LUTE_VERSION}.tar.gz"
tar -czf "${OUT}" -C "${BUILD_DIR}" lute/
sha256sum "${OUT}" | awk '{print $1}' > "${OUT}.sha256"
echo "Built: ${OUT}"
echo "SHA256: $(cat "${OUT}.sha256")"
```

Publish script (`scripts/publish_lute_server.sh`) wraps `gh release create lute-server-v<ver> --generate-notes dist/lute-server-android-arm64-v<ver>.tar.gz{,.sha256}`.

`new_release.sh` gains one optional flag:

```bash
./new_release.sh 1.3.0 37 --with-server 3.10.1
```

Which calls `scripts/publish_lute_server.sh 3.10.1` at the end.

---

## Settings download flow (end to end)

1. App starts. `localServerMode = remote`. No work.
2. User goes to Settings → Server → selects "On-device".
3. Settings widget reads `embeddedServerInstalledVersion` from
   `Settings`. If null, shows "Not installed · ~18 MB" + Download
   button.
4. User taps Download. `EmbeddedServerService.download()` calls
   Kotlin via MethodChannel.
5. Kotlin downloads
   `https://github.com/schlick7/LuteForMobile/releases/download/lute-server-v3.10.1/lute-server-android-arm64-v3.10.1.tar.gz`
   + the `.sha256` sidecar. Streams to
   `${appSupportDir}/lute-server/.cache/lute-server.tar.gz`.
6. Kotlin verifies hash, extracts to
   `${appSupportDir}/lute-server/3.10.1/`. Cleans cache.
7. Posts `ready` event. Settings widget re-renders with Start
   button.
8. User taps Start. Kotlin picks a free port
   (`ServerSocket(0)` then close), writes
   `${appSupportDir}/lute/lute.db` is created on first run by Lute
   itself. Spawns
   `python -m lute.main --port <port> --datapath ${appSupportDir}/lute --local`.
9. Kotlin polls `http://127.0.0.1:<port>/info` every 250ms, up to
   30s. On 200, posts `Started(port)`. On timeout, posts error.
10. Dart stores port in `Settings`. `ApiService.baseUrl` now
    resolves to the embedded server. From the rest of the app's
    perspective, nothing changed.
11. User kills the app. Process dies. On next launch, if
    `localServerMode == onDevice`, the start sequence repeats.
    Install is preserved.

---

## Data migration (Termux → on-device, one-time)

Users with an existing Termux install have a `lute.db` somewhere
under Termux's `$PREFIX/var/lute/`. The settings UI shows a
banner: "Existing Termux data detected — import?" that:

1. Asks for Termux storage permission (already exposed in
   `termux_service.dart:247-255`).
2. Copies `$PREFIX/var/lute/lute.db` (and any
   `userimages/`, `useraudio/`) into
   `${appSupportDir}/lute/`.
3. Validates the DB is a real Lute schema (check for `words`
   table) before swapping it in.
4. Prompts the user to switch `localServerMode` to `onDevice`.

Out of scope for v1 — the user can manually copy the file using a
file manager, and the embedded server will pick it up from
`getApplicationSupportDirectory()/lute/lute.db` if it exists.

---

## Testing strategy

Manual for v1 (no automated Dart-side tests added):

1. **End-to-end on a Pixel 7 (arm64):**
   - Fresh install, default `remote`. App talks to a `lute` server
     on `localhost:5001` via adb reverse. Verify book list, read,
     mark term known.
   - Switch to on-device, download, start. Verify same flows
     without the network server. Verify `lute.db` is created
     and grows.
   - Add a book. Copy `lute.db` off the device. Open with
     desktop Lute. Verify the book is there. (Round-trip data
     test.)
   - Kill the app. Relaunch. Verify on-device server starts
     automatically. Verify data is still there.
   - Uninstall the app, reinstall. Reinstall. Verify on-device
     data is gone (it's under app's private storage, expected
     behavior) — separately, test that a backed-up
     `.lute3` import still works.
2. **iOS smoke:** verify the "On-device" option is hidden, the
   PWA path is unchanged.
3. **Termux regression:** with `localServerMode = termux`,
   verify the existing flow still works exactly as before. No
   regressions in `TermuxBridge.kt` or `termux_service.dart`.

---

## Risks and open questions

1. **Chaquopy startup time.** First call to Python is ~2s on a
   mid-range phone. The lute server itself adds another 1–2s
   for `waitress` to bind. Target: cold start to "ready" under
   5s. If we miss, the spinner needs to be friendly.
2. **Process lifecycle when app is backgrounded.** Without a
   foreground service, Android will kill the process after
   some time. For v1 we accept this: user reopens app,
   server restarts. If users complain, we add a
   `ForegroundService` in v2 (the existing
   `TermuxForegroundService.kt` is a reference impl).
3. **DB file lock.** If the user has both `onDevice` and
   `termux` modes active, they could collide on the same DB
   file. Settings UI enforces mutual exclusion: switching
   to `onDevice` requires `termux` server to be stopped
   first, and vice versa.
4. **WebView / scrape compatibility.** The read endpoint still
   returns HTML. `html_parser.dart` keeps working because
   we're speaking the same contract. (Switching to a
   `read/...json` endpoint is a v2 optimization, not a v1
   requirement.)
5. **Backup file format.** Existing `.lute3` backups (gzipped
   SQLite) work as-is — the embedded server reads them with
   `BackupService` already in place. No format change needed.
6. **Chaquopy license attribution.** The embedded CPython
   runtime is PSF-licensed. Add a "Third-party licenses"
   screen entry that says "Python 3.11.x, PSF License, see
   python.org/psf/license". `scripts/check_chaquopy_license.sh`
   verifies this is bundled.
7. **Storage size.** A `lute.db` with a 500-book library is
   ~50 MB. Add a "Storage usage" line in the on-device card
   so users see what they're spending.

---

## Effort estimate

| Chunk | Time (one person) |
|---|---|
| Chaquopy integration in `android/app/build.gradle`, smoke test | 1 day |
| `EmbeddedServerBridge.kt` + `EmbeddedServerProcess.kt` | 2 days |
| `EmbeddedServerService` Dart side + MethodChannel | 1 day |
| Settings UI (download card, state machine) | 2 days |
| `scripts/build_lute_server.sh` + `publish_lute_server.sh` | 0.5 day |
| Manual testing on a real device + iOS smoke | 1 day |
| Polish: license screen, storage usage, error states | 1 day |
| **Total** | **~8.5 working days** |

That's "ready to ship a beta" in roughly two weeks at a comfortable
pace. The big variable is Chaquopy setup — the gradle plugin is
well-documented but has a couple of "first time you set it up you
fight Gradle for an hour" moments.

---

## What this plan does NOT do

- Not bundling the server in the APK.
- Not re-implementing Lute in Dart.
- Not adding GitHub Actions.
- Not shipping MeCab for Japanese.
- Not supporting 32-bit Android.
- Not removing the Termux path.
- Not switching the read endpoint to JSON (HTML scraping keeps
  working).
- Not changing `ApiService` in any way.
- Not changing the remote-server path in any way.

It is strictly additive: a new option in Settings, a new Kotlin
bridge, a new download flow, and a tarball in GitHub Releases.

---

## Open questions for before we start coding

1. **Chaquopy is the chosen toolchain.** Confirm you're OK with
   the Chaquopy Gradle plugin as a dep. (Alternative:
   PyOxidizer-built static binary, no Chaquopy dep but more
   CI surgery. We already settled on Chaquopy per your answer
   to Q2, this is just a heads-up before I touch `build.gradle`.)
2. **Pinned `LUTE_SERVER_VERSION` starting value.** What do
   you want as the initial pin? I'd go with whatever the
   latest upstream release is (currently `3.10.1` per
   `https://github.com/LuteOrg/lute-v3/releases/latest`).
3. **Where in the existing release flow does the server build
   go?** `new_release.sh` is a single-purpose script. I'd
   leave it alone and add a separate `scripts/release.sh` that
   does the whole thing (APK + PWA + lute-server tarball).
   Or extend `new_release.sh` with a `--with-server` flag. Tell
   me which you prefer.
4. **Settings UI: rename "Termux Integration" to what?** My
   suggestion: "Server" with three options (Remote / On-device
   / Termux). Confirm or pick a different label.
5. **`isUrlValid` for `onDevice` mode.** The current
   `Settings.isUrlValid` (line 12) gates the "Test connection"
   button. For `onDevice`, the connection test is "is the
   embedded server running?". Want me to repurpose the button
   or add a separate "Test embedded server" button?
