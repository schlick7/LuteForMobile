import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';

class AppDrawer extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onNavigate;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsContent = ref.watch(currentViewDrawerSettingsProvider);

    return SizedBox(
      width: settingsContent != null ? 320 : 80,
      child: Drawer(
        child: settingsContent != null
            ? Row(
                children: [
                  _buildNavigationColumn(context),
                  Expanded(child: settingsContent),
                ],
              )
            : _buildNavigationColumn(context),
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
          _buildNavItem(context, Icons.book, 0, 'Reader'),
          _buildNavItem(context, Icons.settings, 1, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    int index,
    String label,
  ) {
    final isSelected = currentIndex == index;
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
              onNavigate(index);
              Navigator.of(context).pop();
            },
            tooltip: label,
          ),
        ],
      ),
    );
  }
}
