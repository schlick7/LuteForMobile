import 'package:flutter/material.dart';
import 'package:lute_for_mobile/features/books/models/book.dart';
import 'package:lute_for_mobile/shared/theme/theme_extensions.dart';

class StatusDistributionBar extends StatelessWidget {
  final Book book;
  final double height;
  final bool showLegend;

  const StatusDistributionBar({
    super.key,
    required this.book,
    this.height = 8,
    this.showLegend = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!book.hasStats || book.statusDistribution == null) {
      return const SizedBox.shrink();
    }

    final totalTerms = book.statusDistribution!
        .asMap()
        .entries
        .where((entry) => entry.key != 6)
        .fold<int>(0, (sum, entry) => sum + entry.value);
    if (totalTerms == 0) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width - 64;
    final segments = <Widget>[];

    double currentLeft = 0.0;
    final statusColors = [
      context.status0,
      context.status1,
      context.status2,
      context.status3,
      context.status4,
      context.status5,
      context.status99,
    ];

    final borderSide = BorderSide(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      width: 1,
    );

    for (int i = 0; i < statusColors.length; i++) {
      final originalIndex = i > 5 ? i + 1 : i;
      final count = book.statusDistribution![originalIndex];
      if (count > 0) {
        final width = (count / totalTerms) * screenWidth;
        final isLastSegment = i == statusColors.length - 1;

        segments.add(
          Positioned(
            left: currentLeft,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: statusColors[i],
                border: Border(
                  right: isLastSegment ? BorderSide.none : borderSide,
                ),
                borderRadius: i == 0
                    ? BorderRadius.only(
                        topLeft: Radius.circular(height / 2),
                        bottomLeft: Radius.circular(height / 2),
                      )
                    : isLastSegment
                    ? BorderRadius.only(
                        topRight: Radius.circular(height / 2),
                        bottomRight: Radius.circular(height / 2),
                      )
                    : null,
              ),
            ),
          ),
        );
        currentLeft += width;
      }
    }

    final barWidget = Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Stack(children: segments),
    );

    if (!showLegend) {
      return barWidget;
    }

    final statusUnknown = book.statusDistribution![0];
    final statusLearning = book.statusDistribution!
        .skip(1)
        .take(5)
        .fold<int>(0, (sum, item) => sum + item);
    final statusKnown = book.statusDistribution![7];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        barWidget,
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              context,
              color: context.status0,
              label: 'Unknown',
              count: statusUnknown,
            ),
            _buildLegendItem(
              context,
              color: context.status1,
              label: 'Learning',
              count: statusLearning,
            ),
            _buildLegendItem(
              context,
              color: context.status99,
              label: 'Known',
              count: statusKnown,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
