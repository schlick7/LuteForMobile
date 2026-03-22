import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../shared/providers/language_data_provider.dart';
import '../../../shared/providers/network_providers.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../providers/stats_provider.dart';

class TermsAddedTodayCard extends ConsumerStatefulWidget {
  const TermsAddedTodayCard({super.key});

  @override
  ConsumerState<TermsAddedTodayCard> createState() =>
      _TermsAddedTodayCardState();
}

class _TermsAddedTodayCardState extends ConsumerState<TermsAddedTodayCard> {
  Future<_TermsAddedStats>? _statsFuture;
  bool _manualLoadRequested = false;
  String? _scopeKey;

  @override
  Widget build(BuildContext context) {
    final isStatsScreenActive =
        ref.watch(currentScreenRouteProvider) == 'stats';
    if (!isStatsScreenActive) {
      return const SizedBox.shrink();
    }

    final settings = ref.watch(settingsProvider);
    final statsState = ref.watch(statsProvider);
    final selectedLanguageName = statsState.value?.selectedLanguage?.language;
    final languageList = ref.watch(languageListProvider).value ?? const [];
    int? selectedLanguageId;
    if (selectedLanguageName != null) {
      for (final language in languageList) {
        if (language.name == selectedLanguageName) {
          selectedLanguageId = language.id;
          break;
        }
      }
    }
    final shouldAutoLoad = settings.autoLoadTermStatsCards;
    final shouldLoad = shouldAutoLoad || _manualLoadRequested;
    final today = DateTime.now();
    final currentScopeKey =
        '${settings.serverUrl}|${selectedLanguageId ?? 'all'}|${today.year}-${today.month}-${today.day}';

    if (_scopeKey != currentScopeKey) {
      _scopeKey = currentScopeKey;
      _statsFuture = null;
    }

    if (!shouldLoad) {
      return _buildCollapsedCard(context, selectedLanguageId);
    }

    if (selectedLanguageName != null && selectedLanguageId == null) {
      return _buildLoadingCard(context);
    }

    _statsFuture ??= _loadStats(selectedLanguageId);

    return FutureBuilder<_TermsAddedStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingCard(context);
        }

        if (snapshot.hasError) {
          return _buildErrorCard(
            context,
            snapshot.error.toString(),
            selectedLanguageId,
          );
        }

        final stats = snapshot.data ?? const _TermsAddedStats.empty();
        return _buildLoadedCard(context, stats);
      },
    );
  }

  Future<_TermsAddedStats> _loadStats(int? langId) async {
    final apiService = ref.read(apiServiceProvider);
    final dailyCounts = <DateTime, int>{};
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int start = 0;
    const batchSize = 1000;
    int recordsTotal = 0;
    bool hasMore = true;

    while (hasMore) {
      final response = await apiService.fetchAllTerms(
        start: start,
        length: batchSize,
        langId: langId,
      );
      final jsonString = response.data ?? '{}';
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final data = (json['data'] as List?) ?? const [];
      recordsTotal = json['recordsTotal'] as int? ?? 0;

      for (final item in data) {
        final row = item as Map<String, dynamic>;
        final statusId = row['StID'] as int? ?? 0;
        if (!_isTrackedStatus(statusId)) {
          continue;
        }

        final createdAt = row['WoCreated'] as String? ?? '';
        if (createdAt.isEmpty) {
          continue;
        }

        final parsed = DateTime.tryParse(createdAt);
        if (parsed == null) {
          continue;
        }

        final date = DateTime(parsed.year, parsed.month, parsed.day);
        dailyCounts.update(date, (value) => value + 1, ifAbsent: () => 1);
      }

      start += data.length;
      hasMore = data.isNotEmpty && start < recordsTotal;
    }

    final todayCount = dailyCounts[todayDate] ?? 0;
    final record = dailyCounts.values.isEmpty
        ? 0
        : dailyCounts.values.reduce((a, b) => a > b ? a : b);

    return _TermsAddedStats(todayCount: todayCount, record: record);
  }

  bool _isTrackedStatus(int statusId) {
    return (statusId >= 1 && statusId <= 5) || statusId == 99;
  }

  Widget _buildCollapsedCard(BuildContext context, int? selectedLanguageId) {
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
                  _statsFuture = _loadStats(selectedLanguageId);
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

  Widget _buildErrorCard(
    BuildContext context,
    String error,
    int? selectedLanguageId,
  ) {
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
                  _statsFuture = _loadStats(selectedLanguageId);
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
