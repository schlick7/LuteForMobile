import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lute_for_mobile/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        initialServerUrlProvider.overrideWithValue(
          prefs.getString('server_url') ?? '',
        ),
      ],
      child: const App(),
    ),
  );
}

final initialServerUrlProvider = Provider<String>((ref) => '');
