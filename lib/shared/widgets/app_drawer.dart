import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/features/books/providers/books_provider.dart';
import 'package:lute_for_mobile/features/books/models/book.dart';

class AppDrawer extends ConsumerWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsContent = ref.watch(currentViewDrawerSettingsProvider);

    return SizedBox(
      width: settingsContent != null ? 320 : 80,
      child: Drawer(
        child: SafeArea(
          child: settingsContent != null
              ? Row(
                  children: [
                    _buildNavigationColumn(context),
                    Expanded(child: settingsContent),
                  ],
                )
              : _buildNavigationColumn(context),
        ),
      ),
    );
  }

  Widget _buildNavigationColumn(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildNavItem(context, Icons.book, 'reader', 'Reader'),
          _buildNavItem(context, Icons.collections_bookmark, 'books', 'Books'),
          _buildNavItem(context, Icons.translate, 'terms', 'Terms'),
          _buildNavItem(context, Icons.bar_chart, 'stats', 'Stats'),
          _buildNavItem(context, Icons.help_outline, 'help', 'Help'),
          _buildNavItem(context, Icons.settings, 'settings', 'Settings'),
          const Spacer(),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    snapshot.data!.version,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String route,
    String label,
  ) {
    final isSelected = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon),
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            onPressed: () {
              onNavigate(route);
              Navigator.of(context).pop();
            },
            tooltip: label,
          ),
        ],
      ),
    );
  }
}
