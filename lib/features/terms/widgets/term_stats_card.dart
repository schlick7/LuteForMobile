import 'package:flutter/material.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../models/term_stats.dart';

class TermStatsCard extends StatelessWidget {
  final TermStats stats;
  final String? languageName;

  const TermStatsCard({super.key, required this.stats, this.languageName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Term Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (languageName != null)
                  Text(
                    languageName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow(context, 'Learning 1', stats.status1, status: '1'),
            _buildStatRow(context, 'Learning 2', stats.status2, status: '2'),
            _buildStatRow(context, 'Learning 3', stats.status3, status: '3'),
            _buildStatRow(context, 'Learning 4', stats.status4, status: '4'),
            _buildStatRow(context, 'Learning 5', stats.status5, status: '5'),
            _buildStatRow(context, 'Well Known', stats.status99, status: '99'),
            const Divider(height: 24),
            _buildStatRow(context, 'Total', stats.total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    int count, {
    String? status,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (status != null && !isTotal)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.getStatusColor(status),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      width: 1,
                    ),
                  ),
                ),
              if (status != null && !isTotal) const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
