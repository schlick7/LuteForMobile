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
import 'package:lute_for_mobile/core/services/server_health_service.dart';
import 'package:lute_for_mobile/core/services/termux_service.dart';
import 'package:lute_for_mobile/shared/providers/server_status_provider.dart';
import 'package:lute_for_mobile/hive_registrar.g.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final localUrl = prefs.getString('local_url') ?? '';
  final useTermux = prefs.getBool('use_termux') ?? false;
  final serverUrl = useTermux ? Settings.termuxUrl : localUrl;

  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final cacheDir = await getApplicationCacheDirectory();
    await Hive.initFlutter(cacheDir.path);
  }
  Hive.registerAdapters();

  ServerStatusManager.setConnecting();

  Future<bool>? androidHealthCheck;
  if (useTermux && serverUrl == Settings.termuxUrl) {
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
