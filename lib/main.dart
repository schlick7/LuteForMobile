import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lute_for_mobile/app.dart';
import 'package:lute_for_mobile/core/providers/initial_providers.dart';
import 'package:lute_for_mobile/core/cache/tooltip_cache_service.dart';
import 'package:lute_for_mobile/core/cache/books_cache_service.dart';
import 'package:lute_for_mobile/core/cache/term_cache_service.dart';
import 'package:lute_for_mobile/features/stats/repositories/stats_repository.dart';
import 'package:lute_for_mobile/core/network/api_service.dart';
import 'package:lute_for_mobile/core/services/server_health_service.dart';
import 'package:lute_for_mobile/shared/providers/server_status_provider.dart';
import 'package:lute_for_mobile/hive_registrar.g.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final localUrl = prefs.getString('local_url') ?? '';
  final useTermux = prefs.getBool('use_termux') ?? false;
  final serverUrl = useTermux ? Settings.termuxUrl : localUrl;

  Hive.registerAdapters();

  await TooltipCacheService.getInstance().initialize();
  await BooksCacheService.getInstance().initialize();
  await StatsRepository.initialize();
  await TermCacheService.getInstance().initialize();

  ServerStatusManager.setConnecting();

  if (serverUrl.isNotEmpty) {
    print('main.dart: Checking server health at $serverUrl');
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
