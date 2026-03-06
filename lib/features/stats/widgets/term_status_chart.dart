import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../terms/providers/terms_provider.dart';
import '../../terms/models/term_stats.dart';
import '../../../shared/theme/theme_extensions.dart';

class TermStatusChart extends ConsumerWidget {
  const TermStatusChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsState = ref.watch(termsProvider);
    final stats = termsState.stats;

    if (stats.total == 0) {
      return const SizedBox.shrink();
    }

    final sections = _buildSections(stats, context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Term Status Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (event is FlTapUpEvent && pieTouchResponse != null) {
                        final touchedSection = pieTouchResponse.touchedSection;
                        if (touchedSection != null) {
                          final index = touchedSection.touchedSectionIndex;
                          _showStatusDetails(context, stats, index);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(context, stats),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    TermStats stats,
    BuildContext context,
  ) {
    final statusColors = _getStatusColors(context);
    final labelTextStyles = {
      '1': TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: context.getStatusTextColor('1'),
      ),
      '2': TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: context.getStatusTextColor('2'),
      ),
      '3': TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: context.getStatusTextColor('3'),
      ),
      '4': TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: context.getStatusTextColor('4'),
      ),
      '5': TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: context.getStatusTextColor('5'),
      ),
      '99': TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: context.getStatusTextColor('99'),
      ),
    };

    return [
      PieChartSectionData(
        value: stats.status1.toDouble(),
        title: 'L1',
        color: statusColors['1'] ?? context.appColorScheme.text.secondary,
        radius: 50,
        titleStyle: labelTextStyles['1'],
      ),
      PieChartSectionData(
        value: stats.status2.toDouble(),
        title: 'L2',
        color: statusColors['2'] ?? context.appColorScheme.text.secondary,
        radius: 50,
        titleStyle: labelTextStyles['2'],
      ),
      PieChartSectionData(
        value: stats.status3.toDouble(),
        title: 'L3',
        color: statusColors['3'] ?? context.appColorScheme.text.secondary,
        radius: 50,
        titleStyle: labelTextStyles['3'],
      ),
      PieChartSectionData(
        value: stats.status4.toDouble(),
        title: 'L4',
        color: statusColors['4'] ?? context.appColorScheme.text.secondary,
        radius: 50,
        titleStyle: labelTextStyles['4'],
      ),
      PieChartSectionData(
        value: stats.status5.toDouble(),
        title: 'L5',
        color: statusColors['5'] ?? context.appColorScheme.text.secondary,
        radius: 50,
        titleStyle: labelTextStyles['5'],
      ),
      PieChartSectionData(
        value: stats.status99.toDouble(),
        title: 'WK',
        color: statusColors['99'] ?? context.appColorScheme.text.secondary,
        radius: 50,
        titleStyle: labelTextStyles['99'],
      ),
    ];
  }

  Map<String, Color> _getStatusColors(BuildContext context) {
    return {
      '1': context.status1,
      '2': context.status2,
      '3': context.status3,
      '4': context.status4,
      '5': context.status5,
      '99': context.status99,
    };
  }

  Widget _buildLegend(BuildContext context, TermStats stats) {
    final statusColors = _getStatusColors(context);
    final statusKeys = ['1', '2', '3', '4', '5', '99'];
    final labels = ['L1', 'L2', 'L3', 'L4', 'L5', 'WK'];
    final values = [
      stats.status1,
      stats.status2,
      stats.status3,
      stats.status4,
      stats.status5,
      stats.status99,
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(6, (index) {
        final color =
            statusColors[statusKeys[index]] ??
            context.appColorScheme.text.secondary;
        final value = values[index];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${labels[index]}: $value',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }),
    );
  }

  void _showStatusDetails(BuildContext context, TermStats stats, int index) {
    final labels = [
      'Learning 1',
      'Learning 2',
      'Learning 3',
      'Learning 4',
      'Learning 5',
      'Well Known',
    ];
    final values = [
      stats.status1,
      stats.status2,
      stats.status3,
      stats.status4,
      stats.status5,
      stats.status99,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labels[index]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Count: ${values[index]} terms'),
            const SizedBox(height: 8),
            Text(
              'Percentage: ${stats.total > 0 ? ((values[index] / stats.total) * 100).toStringAsFixed(1) : 0}%',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
