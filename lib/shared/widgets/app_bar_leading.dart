import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/server_status_provider.dart';
import '../providers/global_loading_provider.dart';

class AppBarLeading extends ConsumerWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const AppBarLeading({super.key, this.scaffoldKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(globalLoadingProvider);
    final isReachable = ref.watch(serverStatusProvider).isReachable;

    // Error state takes priority
    if (!isReachable) {
      return IconButton(
        icon: const Icon(Icons.warning),
        color: Colors.red,
        onPressed: () => _openDrawer(context),
      );
    }

    // Loading state - spinner overlay on hamburger
    if (isLoading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _openDrawer(context),
          ),
          const CircularProgressIndicator(strokeWidth: 2),
        ],
      );
    }

    // Normal state - hamburger menu
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => _openDrawer(context),
    );
  }

  void _openDrawer(BuildContext context) {
    if (scaffoldKey != null && scaffoldKey!.currentState != null) {
      scaffoldKey!.currentState!.openDrawer();
    } else {
      Scaffold.of(context).openDrawer();
    }
  }
}
