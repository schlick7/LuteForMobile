import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lute_for_mobile/app.dart';
import 'package:lute_for_mobile/core/providers/initial_providers.dart';
import 'package:lute_for_mobile/core/network/api_service.dart';
import 'package:lute_for_mobile/core/services/embedded_server_service.dart';
import 'package:lute_for_mobile/core/services/server_health_service.dart';
import 'package:lute_for_mobile/core/services/termux_service.dart';
import 'package:lute_for_mobile/shared/providers/server_status_provider.dart';
import 'package:lute_for_mobile/hive_registrar.g.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final localUrl = prefs.getString('local_url') ?? '';

  // Resolve localServerMode (with legacy migration from use_termux /
  // termux_integration_enabled).
  LocalServerMode localServerMode = LocalServerMode.remote;
  final storedMode = prefs.getString('local_server_mode');
  if (storedMode != null) {
    localServerMode = LocalServerMode.values.firstWhere(
      (m) => m.name == storedMode,
      orElse: () => LocalServerMode.remote,
    );
  } else {
    final legacyUseTermux = prefs.getBool('use_termux') ?? false;
    final legacyTermuxIntegration =
        prefs.getBool('termux_integration_enabled') ?? false;
    if (legacyTermuxIntegration && legacyUseTermux) {
      localServerMode = LocalServerMode.termux;
    }
  }

  String serverUrl;
  switch (localServerMode) {
    case LocalServerMode.remote:
      serverUrl = localUrl;
      break;
    case LocalServerMode.termux:
      serverUrl = Settings.termuxUrl;
      break;
    case LocalServerMode.onDevice:
      // Try to start the embedded server so the URL is available immediately.
      // If the user hasn't installed the artifact yet, this fails silently
      // and the URL stays empty; the settings UI prompts them to download.
      try {
        if (!kIsWeb) {
          await EmbeddedServerService.instance.refresh();
          final snap = EmbeddedServerService.instance.snapshot;
          if (snap.installedVersion != null) {
            serverUrl = await EmbeddedServerService.instance.start();
          } else {
            serverUrl = '';
          }
        } else {
          serverUrl = '';
        }
      } catch (e) {
        print('main.dart: embedded server start failed: $e');
        serverUrl = '';
      }
      break;
  }

  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final cacheDir = await getApplicationCacheDirectory();
    await Hive.initFlutter(cacheDir.path);
  }
  Hive.registerAdapters();

  ServerStatusManager.setConnecting();

  Future<bool>? androidHealthCheck;
  if (localServerMode == LocalServerMode.termux &&
      serverUrl == Settings.termuxUrl) {
    androidHealthCheck = TermuxService.isServerRunning(serverUrl);
  }

  if (androidHealthCheck != null) {
    final isRunning = await androidHealthCheck;
    print('main.dart: Android server check: $isRunning');
    ServerStatusManager.setReachable(isRunning);
  } else if (serverUrl.isNotEmpty) {
    final isServerReachable = await ServerHealthService.isReachable(serverUrl);
    print('main.dart: Server health check result: $isServerReachable');
    ServerStatusManager.setReachable(isServerReachable);
  } else {
    ServerStatusManager.setReachable(false);
  }

  ServerStatusManager.setInitialCheckComplete(true);

  if (serverUrl.isNotEmpty) {
    final apiService = ApiService(baseUrl: serverUrl);
    apiService.triggerAutoBackup();
  }

  runApp(
    ProviderScope(
      overrides: [initialServerUrlProvider.overrideWithValue(serverUrl)],
      child: const App(),
    ),
  );
}
