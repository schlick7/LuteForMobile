import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/cache/providers/term_cache_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../shared/providers/network_providers.dart';
import '../../../shared/theme/theme_extensions.dart';

class TermsAddedTodayCard extends ConsumerStatefulWidget {
  const TermsAddedTodayCard({super.key});

  @override
  ConsumerState<TermsAddedTodayCard> createState() =>
      _TermsAddedTodayCardState();
}

class _TermsAddedTodayCardState extends ConsumerState<TermsAddedTodayCard> {
  Future<_TermsAddedStats>? _statsFuture;
  bool _manualLoadRequested = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final shouldAutoLoad = settings.autoLoadTermStatsCards;
    final shouldLoad = shouldAutoLoad || _manualLoadRequested;

    if (!shouldLoad) {
      return _buildCollapsedCard(context);
    }

    _statsFuture ??= _loadStats();

    return FutureBuilder<_TermsAddedStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingCard(context);
        }

        if (snapshot.hasError) {
          return _buildErrorCard(context, snapshot.error.toString());
        }

        final stats = snapshot.data ?? const _TermsAddedStats.empty();
        return _buildLoadedCard(context, stats);
      },
    );
  }

  Future<_TermsAddedStats> _loadStats() async {
    final contentService = ref.read(contentServiceProvider);
    final termCacheService = ref.read(termCacheServiceProvider);

    final todayCount = await contentService.getTermCount(
      statusMin: 1,
      statusMax: 99,
      ageMin: 0,
      ageMax: 0,
    );

    final totalTrackedTerms = await contentService.getTermCount(
      statusMin: 1,
      statusMax: 99,
    );

    var cachedTerms = await termCacheService.getAllTerms();
    final cachedTrackedTerms = cachedTerms
        .where((term) => term.statusId > 0 && term.statusId <= 99)
        .length;

    if (cachedTrackedTerms < totalTrackedTerms) {
      await contentService.warmTermCache();
      cachedTerms = await termCacheService.getAllTerms();
    }

    final dailyCounts = <DateTime, int>{};
    for (final term in cachedTerms) {
      if (term.statusId <= 0 || term.statusId > 99 || term.createdAt.isEmpty) {
        continue;
      }

      final parsed = DateTime.tryParse(term.createdAt);
      if (parsed == null) continue;

      final date = DateTime(parsed.year, parsed.month, parsed.day);
      dailyCounts.update(date, (value) => value + 1, ifAbsent: () => 1);
    }

    final record = dailyCounts.values.isEmpty
        ? 0
        : dailyCounts.values.reduce((a, b) => a > b ? a : b);

    return _TermsAddedStats(todayCount: todayCount, record: record);
  }

  Widget _buildCollapsedCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms Added Today',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Disabled automatic loading',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColorScheme.text.secondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _manualLoadRequested = true;
                  _statsFuture = _loadStats();
                });
              },
              child: const Text('Load'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Terms Added Today',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms Added Today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.error),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _statsFuture = _loadStats();
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedCard(BuildContext context, _TermsAddedStats stats) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms Added Today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              stats.todayCount.toString(),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Record: ${stats.record}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appColorScheme.text.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsAddedStats {
  final int todayCount;
  final int record;

  const _TermsAddedStats({required this.todayCount, required this.record});

  const _TermsAddedStats.empty() : this(todayCount: 0, record: 0);
}
