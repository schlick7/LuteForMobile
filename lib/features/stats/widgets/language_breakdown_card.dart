import 'package:flutter/material.dart';
import '../models/language_stats.dart';

class LanguageBreakdownCard extends StatelessWidget {
  final List<LanguageReadingStats> languages;

  const LanguageBreakdownCard({super.key, required this.languages});

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalWords = languages.fold<int>(
      0,
      (sum, lang) => sum + lang.totalWords,
    );
    final sortedLanguages = [...languages]
      ..sort((a, b) => b.totalWords.compareTo(a.totalWords));

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...sortedLanguages.map(
              (lang) => _buildLanguageRow(context, lang, totalWords),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow(
    BuildContext context,
    LanguageReadingStats lang,
    int totalWords,
  ) {
    final percentage = totalWords > 0
        ? (lang.totalWords / totalWords * 100).toStringAsFixed(1)
        : '0';
    final weeklyWords = _getWeeklyWords(lang);
    final dailyAverage = _getDailyAverage(lang);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lang.language,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${_formatNumber(lang.totalWords)} words',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalWords > 0 ? lang.totalWords / totalWords : 0,
              minHeight: 8,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$percentage of total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'Weekly: ${_formatNumber(weeklyWords)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Daily avg: ${_formatNumber(dailyAverage)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getWeeklyWords(LanguageReadingStats lang) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - 7);

    return lang.dailyStats
        .where((stat) => !stat.date.isBefore(weekStart))
        .fold<int>(0, (sum, stat) => sum + stat.wordcount);
  }

  int _getDailyAverage(LanguageReadingStats lang) {
    if (lang.dailyStats.isEmpty) return 0;
    final total = lang.dailyStats.fold<int>(
      0,
      (sum, stat) => sum + stat.wordcount,
    );
    return (total / lang.dailyStats.length).round();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
