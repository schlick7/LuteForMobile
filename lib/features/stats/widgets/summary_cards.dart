import 'dart:math';
import 'package:flutter/material.dart';
import '../models/language_stats.dart';
import '../models/stats_data.dart';

class SummaryCards extends StatelessWidget {
  final List<LanguageReadingStats> languages;

  const SummaryCards({super.key, required this.languages});

  @override
  Widget build(BuildContext context) {
    final todayStats = _getTodayStats();
    final weekStats = _getWeekStats();
    final totalStats = _getTotalStats();
    final streakStats = _getStreakStats();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                context,
                icon: Icons.today,
                label: 'Today',
                value: _formatNumber(todayStats.wordcount),
                subtitle: '${todayStats.days} days active',
                iconColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                context,
                icon: Icons.date_range,
                label: 'This Week',
                value: _formatNumber(weekStats.wordcount),
                subtitle: '${weekStats.days} days active',
                iconColor: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          context,
          icon: Icons.local_fire_department,
          label: 'Streak',
          value: '${streakStats.currentStreak}',
          subtitle: 'Longest: ${streakStats.longestStreak} days',
          iconColor: Colors.orange,
          isLarge: true,
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          context,
          icon: Icons.library_books,
          label: 'Total Words',
          value: _formatNumber(totalStats.wordcount),
          subtitle:
              '${totalStats.days} days across ${languages.length} language${languages.length != 1 ? 's' : ''}',
          iconColor: Theme.of(context).colorScheme.tertiary,
          isLarge: true,
        ),
      ],
    );
  }

  ({int wordcount, int days}) _getTodayStats() {
    final today = DateTime.now();
    int wordcount = 0;
    int days = 0;

    for (final lang in languages) {
      final todayStat = lang.dailyStats.firstWhere(
        (stat) =>
            stat.date.year == today.year &&
            stat.date.month == today.month &&
            stat.date.day == today.day,
        orElse: () => DailyReadingStats(
          date: DateTime.now(),
          wordcount: 0,
          runningTotal: 0,
        ),
      );
      if (todayStat.wordcount > 0) {
        wordcount += todayStat.wordcount;
        days++;
      }
    }

    return (wordcount: wordcount, days: days);
  }

  ({int currentStreak, int longestStreak}) _getStreakStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final activeDates = <DateTime>{};

    for (final lang in languages) {
      for (final stat in lang.dailyStats) {
        if (stat.wordcount > 0) {
          final dateOnly = DateTime(
            stat.date.year,
            stat.date.month,
            stat.date.day,
          );
          activeDates.add(dateOnly);
        }
      }
    }

    if (activeDates.isEmpty) {
      return (currentStreak: 0, longestStreak: 0);
    }

    final sortedDates = activeDates.toList()..sort();

    int currentStreak = 0;
    var checkDate = today;

    if (activeDates.contains(today)) {
      currentStreak = 1;
      checkDate = yesterday;
    } else if (activeDates.contains(yesterday)) {
      currentStreak = 1;
      checkDate = yesterday.subtract(const Duration(days: 1));
    } else {
      currentStreak = 0;
      checkDate = yesterday;
    }

    while (activeDates.contains(checkDate)) {
      currentStreak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    int longestStreak = 0;
    int tempStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = sortedDates[i - 1];
      final currDate = sortedDates[i];
      if (currDate.difference(prevDate).inDays == 1) {
        tempStreak++;
      } else {
        longestStreak = max(longestStreak, tempStreak);
        tempStreak = 1;
      }
    }
    longestStreak = max(longestStreak, tempStreak);

    return (currentStreak: currentStreak, longestStreak: longestStreak);
  }

  ({int wordcount, int days}) _getWeekStats() {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - 7);
    int wordcount = 0;
    final activeDays = <String>{};

    for (final lang in languages) {
      for (final stat in lang.dailyStats) {
        if (!stat.date.isBefore(weekStart)) {
          wordcount += stat.wordcount;
          activeDays.add(
            '${stat.date.year}-${stat.date.month}-${stat.date.day}',
          );
        }
      }
    }

    return (wordcount: wordcount, days: activeDays.length);
  }

  ({int wordcount, int days}) _getTotalStats() {
    int wordcount = 0;
    final activeDays = <String>{};

    for (final lang in languages) {
      for (final stat in lang.dailyStats) {
        wordcount += stat.wordcount;
        activeDays.add('${stat.date.year}-${stat.date.month}-${stat.date.day}');
      }
    }

    return (wordcount: wordcount, days: activeDays.length);
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color iconColor,
    bool isLarge = false,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: isLarge ? 28 : 24, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLarge ? 12 : 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isLarge ? 36 : 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
