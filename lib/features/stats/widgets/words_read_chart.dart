import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/language_stats.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/utils/number_formatting.dart';

class WordsReadChart extends StatelessWidget {
  final List<LanguageReadingStats> languages;

  const WordsReadChart({super.key, required this.languages});

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return const SizedBox.shrink();
    }

    final allDataPoints = <DateTime>{};
    for (final lang in languages) {
      for (final stat in lang.dailyStats) {
        allDataPoints.add(stat.date);
      }
    }

    if (allDataPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = allDataPoints.toList()..sort();
    final minDate = sortedDates.first;
    final maxDate = sortedDates.last;

    final lineBarsData = _createLineData(languages, minDate, maxDate);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Words Read Over Time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineBarsData: lineBarsData,
                  titlesData: _buildTitlesData(minDate, maxDate),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: _calculateInterval(lineBarsData),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: context.appColorScheme.border.outline,
                      ),
                      left: BorderSide(
                        color: context.appColorScheme.border.outline,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: maxDate.difference(minDate).inDays.toDouble(),
                  minY: _calculateMinY(lineBarsData),
                  maxY: _calculateMaxY(lineBarsData),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => context
                          .appColorScheme
                          .background
                          .surfaceContainerHighest,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final lineIndex = spot.barIndex;
                          final language = languages[lineIndex];
                          return LineTooltipItem(
                            '${language.language}: ${formatNumber(spot.y.toInt())}',
                            TextStyle(
                              color: lineBarsData[lineIndex].color,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _createLineData(
    List<LanguageReadingStats> languages,
    DateTime minDate,
    DateTime maxDate,
  ) {
    final colors = _getLanguageColors();
    int colorIndex = 0;

    return languages.map((lang) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      final spots = <FlSpot>[];

      for (final stat in lang.dailyStats) {
        if (!stat.date.isBefore(minDate) && !stat.date.isAfter(maxDate)) {
          final daysFromStart = stat.date.difference(minDate).inDays.toDouble();
          spots.add(FlSpot(daysFromStart, stat.runningTotal.toDouble()));
        }
      }

      return LineChartBarData(
        spots: spots,
        isCurved: false,
        color: color,
        barWidth: 2.5,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.1),
        ),
      );
    }).toList();
  }

  FlTitlesData _buildTitlesData(DateTime minDate, DateTime maxDate) {
    final daysDiff = maxDate.difference(minDate).inDays;
    int tickInterval;

    if (daysDiff <= 7) {
      tickInterval = 1;
    } else if (daysDiff <= 30) {
      tickInterval = 5;
    } else if (daysDiff <= 90) {
      tickInterval = 15;
    } else if (daysDiff <= 365) {
      tickInterval = 30;
    } else {
      tickInterval = 60;
    }

    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: tickInterval.toDouble(),
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final date = minDate.add(Duration(days: value.toInt()));
            return Text(
              '${date.month}/${date.day}',
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: _calculateInterval(
            _createLineData(languages, minDate, maxDate),
          ),
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              formatNumber(value.toInt()),
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _calculateMaxY(List<LineChartBarData> lines) {
    double maxY = 0;
    for (final line in lines) {
      for (final spot in line.spots) {
        if (spot.y > maxY) maxY = spot.y;
      }
    }
    return maxY > 0 ? maxY * 1.1 : 100;
  }

  double _calculateMinY(List<LineChartBarData> lines) {
    double minY = double.infinity;
    for (final line in lines) {
      for (final spot in line.spots) {
        if (spot.y < minY) minY = spot.y;
      }
    }
    if (minY == double.infinity) return 0;
    final maxY = _calculateMaxY(lines);
    final range = maxY - minY;
    if (range <= 0) return 0;
    final padding = range * 0.1;
    final padded = minY - padding;
    return padded < 0 ? 0 : padded;
  }

  double _calculateInterval(List<LineChartBarData> lines) {
    final maxY = _calculateMaxY(lines);
    final minY = _calculateMinY(lines);
    final range = maxY - minY;
    if (range <= 1000) return 200;
    if (range <= 10000) return 2000;
    if (range <= 50000) return 10000;
    if (range <= 100000) return 20000;
    return 50000;
  }

  List<Color> _getLanguageColors() {
    // Intentional fixed palette to keep language series visually distinct.
    return [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.cyan,
      Colors.indigo,
    ];
  }

  Widget _buildLegend(BuildContext context) {
    final colors = _getLanguageColors();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: languages.asMap().entries.map((entry) {
        final index = entry.key;
        final lang = entry.value;
        final color = colors[index % colors.length];

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
            Text(lang.language, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
  }
}
