import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lute_for_mobile/app.dart';
import 'package:lute_for_mobile/core/providers/initial_providers.dart';
import 'package:lute_for_mobile/core/cache/tooltip_cache_service.dart';
import 'package:lute_for_mobile/core/cache/term_cache_service.dart';
import 'package:lute_for_mobile/core/cache/books_cache_service.dart';
import 'package:lute_for_mobile/features/stats/repositories/stats_repository.dart';
import 'package:lute_for_mobile/core/network/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final serverUrl = prefs.getString('server_url') ?? '';

  await TooltipCacheService.getInstance().initialize();
  await BooksCacheService.getInstance().initialize();
  await StatsRepository.initialize();
  await TermCacheService.getInstance().initialize();

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
