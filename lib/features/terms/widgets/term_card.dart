import 'package:flutter/material.dart';
import '../models/term.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/utils/language_flag_mapper.dart';

class TermCard extends StatelessWidget {
  final Term term;
  final VoidCallback onTap;

  const TermCard({super.key, required this.term, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      term.text,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              if (term.translation != null && term.translation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    term.translation!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appColorScheme.text.secondary,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    getFlagForLanguage(term.language) ?? '🌐',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    term.language,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  if (term.tags != null && term.tags!.isNotEmpty)
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: context.appColorScheme.text.secondary,
                    ),
                  if (term.tags != null && term.tags!.isNotEmpty)
                    const SizedBox(width: 4),
                  if (term.tags != null && term.tags!.isNotEmpty)
                    Text(
                      term.tags!.take(2).join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final color = context.getStatusColorForVisualization(
      term.status.toString(),
    );
    final textColor = color.computeLuminance() > 0.5
        ? context.appColorScheme.text.primary
        : context.appColorScheme.status.highlightedText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        term.statusLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
