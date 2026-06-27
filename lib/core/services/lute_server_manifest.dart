import 'package:lute_for_mobile/features/settings/models/settings.dart';

/// Helpers for the on-device lute-v3 server artifact URLs.
///
/// The artifact is published under a tag like `lute-server-v3.10.1`
/// in the LuteForMobile GitHub Releases page. The app is pinned to a
/// single lute version at build time via [Settings.luteServerPinnedVersion].
class LuteServerManifest {
  LuteServerManifest._();

  /// Tag for the lute-server release that this app build expects.
  /// Format: lute-server-v<lute_version>
  static String get releaseTag =>
      'lute-server-v${Settings.luteServerPinnedVersion}';

  /// Filename of the arm64 Android tarball inside the release.
  static String get arm64TarballName =>
      'lute-server-android-arm64-v${Settings.luteServerPinnedVersion}.tar.gz';

  /// Filename of the SHA256 sidecar that accompanies the tarball.
  static String get arm64Sha256Name => '$arm64TarballName.sha256';

  /// Full download URL for the tarball.
  static String get arm64TarballUrl =>
      '${Settings.luteServerReleaseBase}/$releaseTag/$arm64TarballName';

  /// Full download URL for the SHA256 sidecar.
  static String get arm64Sha256Url =>
      '${Settings.luteServerReleaseBase}/$releaseTag/$arm64Sha256Name';

  /// URL for the GitHub releases API to check for a newer lute-server
  /// release than the pinned one. We don't auto-update; this is for the
  /// manual "Check for update" button.
  static const String latestReleaseApiUrl =
      'https://api.github.com/repos/schlick7/LuteForMobile/releases';

  /// Directory under [getApplicationSupportDirectory] where the
  /// downloaded artifact is extracted. Hidden from the user's file
  /// manager.
  static const String installDirName = 'lute-server';

  /// Subdirectory for a specific version, e.g. `lute-server/3.10.1/`.
  /// The lute version directory holds the extracted Python runtime,
  /// lute-deps/, lute package, and the lute-server launcher script.
  static String installDirFor(String version) =>
      '$installDirName/$version';

  /// Directory under [getApplicationSupportDirectory] where the
  /// lute.db file (and userimages, useraudio, backups) live. Same
  /// layout as the desktop Lute v3 server, byte-compatible.
  static const String luteDataDirName = 'lute';

  /// The database filename inside [luteDataDirName].
  static const String luteDbFileName = 'lute.db';
}
