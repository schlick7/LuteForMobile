import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/logger/widget_logger.dart';
import 'theme/theme_extensions.dart';

class HomeScreen extends ConsumerWidget {
  static int _buildCount = 0;

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _buildCount++;
    WidgetLogger.logRebuild('HomeScreen', _buildCount);
    return Scaffold(
      appBar: AppBar(
        title: const Text('LuteForMobile'),
        backgroundColor: context.m3PrimaryContainer,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/reader');
          },
          child: const Text('Open Reader'),
        ),
      ),
    );
  }
}
