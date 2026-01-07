import 'package:flutter/material.dart';
import '../models/term_stats.dart';

class TermStatsCard extends StatelessWidget {
  final TermStats stats;

  const TermStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Term Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow(context, 'Learning 1', stats.status1),
            _buildStatRow(context, 'Learning 2', stats.status2),
            _buildStatRow(context, 'Learning 3', stats.status3),
            _buildStatRow(context, 'Learning 4', stats.status4),
            _buildStatRow(context, 'Learning 5', stats.status5),
            _buildStatRow(context, 'Well Known', stats.status99),
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
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
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
