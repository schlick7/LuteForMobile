import 'package:flutter/material.dart';
import '../models/language_stats.dart';
import '../../../shared/theme/theme_extensions.dart';

class ReadingMilestonesCard extends StatelessWidget {
  final List<LanguageReadingStats> languages;

  const ReadingMilestonesCard({super.key, required this.languages});

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }

    final dailyTotals = _getDailyTotals();
    final milestones = [
      ('1000+', _countDaysAtOrAbove(dailyTotals, 1000)),
      ('5000+', _countDaysAtOrAbove(dailyTotals, 5000)),
      ('10000+', _countDaysAtOrAbove(dailyTotals, 10000)),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Milestones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...milestones.map(
              (milestone) => _buildMilestoneRow(
                context,
                label: milestone.$1,
                total: milestone.$2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, int> _getDailyTotals() {
    final dailyTotals = <DateTime, int>{};

    for (final lang in languages) {
      for (final stat in lang.dailyStats) {
        final date = DateTime(stat.date.year, stat.date.month, stat.date.day);
        dailyTotals.update(
          date,
          (value) => value + stat.wordcount,
          ifAbsent: () => stat.wordcount,
        );
      }
    }

    return dailyTotals;
  }

  int _countDaysAtOrAbove(Map<DateTime, int> dailyTotals, int threshold) {
    return dailyTotals.values.where((total) => total >= threshold).length;
  }

  Widget _buildMilestoneRow(
    BuildContext context, {
    required String label,
    required int total,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.appColorScheme.background.surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              '$total days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appColorScheme.text.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
