import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lute_for_mobile/app.dart';
import 'package:lute_for_mobile/core/providers/initial_providers.dart';
import 'package:lute_for_mobile/core/cache/tooltip_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final serverUrl = prefs.getString('server_url') ?? '';

  // Initialize tooltip cache
  await TooltipCacheService.getInstance().initialize();

  runApp(
    ProviderScope(
      overrides: [initialServerUrlProvider.overrideWithValue(serverUrl)],
      child: const App(),
    ),
  );
}
