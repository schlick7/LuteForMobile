import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

class PeriodFilterWidget extends ConsumerWidget {
  const PeriodFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(statsPeriodProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: StatsPeriod.values.map((period) {
          final isSelected = period == selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(_getPeriodLabel(period)),
              onSelected: (selected) {
                if (selected) {
                  ref.read(statsProvider.notifier).setPeriod(period);
                }
              },
              avatar: Icon(
                _getPeriodIcon(period),
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodLabel(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return '7D';
      case StatsPeriod.month:
        return '30D';
      case StatsPeriod.quarter:
        return '90D';
      case StatsPeriod.year:
        return '1Y';
      case StatsPeriod.all:
        return 'All';
    }
  }

  IconData _getPeriodIcon(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return Icons.weekend;
      case StatsPeriod.month:
        return Icons.calendar_month;
      case StatsPeriod.quarter:
        return Icons.date_range;
      case StatsPeriod.year:
        return Icons.calendar_today;
      case StatsPeriod.all:
        return Icons.all_inclusive;
    }
  }
}
