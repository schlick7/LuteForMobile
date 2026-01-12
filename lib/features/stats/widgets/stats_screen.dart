import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../providers/stats_provider.dart';
import 'summary_cards.dart';
import 'period_filter_widget.dart';
import 'language_filter_widget.dart';
import 'words_read_chart.dart';
import 'term_status_chart.dart';
import 'language_breakdown_card.dart';

class StatsScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const StatsScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (widget.scaffoldKey != null &&
                  widget.scaffoldKey!.currentState != null) {
                widget.scaffoldKey!.currentState!.openDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        title: const Text('Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(statsProvider.notifier).refreshStats(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: state.when(
        loading: () =>
            const Center(child: LoadingIndicator(message: 'Loading stats...')),
        error: (err, stack) => ErrorDisplay(
          message: err.toString(),
          onRetry: () => ref.read(statsProvider.notifier).loadStats(),
        ),
        data: (statsState) => _buildStatsContent(context, statsState),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, StatsState state) {
    if (state.languages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No stats available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start reading to see your statistics',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final filteredLanguages = ref
        .read(statsProvider.notifier)
        .filteredLanguages;

    return RefreshIndicator(
      onRefresh: () => ref.read(statsProvider.notifier).refreshStats(),
      child: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SummaryCards(languages: filteredLanguages),
          ),
          const SizedBox(height: 8),
          const PeriodFilterWidget(),
          const SizedBox(height: 8),
          const LanguageFilterWidget(),
          const SizedBox(height: 8),
          WordsReadChart(languages: filteredLanguages),
          const TermStatusChart(),
          LanguageBreakdownCard(languages: filteredLanguages),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
