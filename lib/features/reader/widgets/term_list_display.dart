import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../models/term_tooltip.dart';
import '../utils/sentence_parser.dart';
import '../../../shared/theme/theme_extensions.dart';

List<TextItem> extractUniqueTerms(CustomSentence? sentence) {
  if (sentence == null) return [];

  final Map<int, TextItem> uniqueTerms = {};
  for (final item in sentence!.textItems) {
    if (item.wordId != null) {
      uniqueTerms[item.wordId!] = item;
    }
  }

  final termList = uniqueTerms.values.toList();
  termList.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
  return termList;
}

class TermListDisplay extends StatelessWidget {
  final CustomSentence? sentence;
  final void Function(TextItem, Offset)? onTermTap;
  final void Function(TextItem)? onTermDoubleTap;
  final Map<int, TermTooltip> tooltips;

  const TermListDisplay({
    super.key,
    required this.sentence,
    this.onTermTap,
    this.onTermDoubleTap,
    required this.tooltips,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueTerms = extractUniqueTerms(sentence);

    if (uniqueTerms.isEmpty) {
      return const Center(child: Text('No terms in this sentence'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: uniqueTerms.length,
      itemBuilder: (context, index) {
        final term = uniqueTerms[index];
        return _buildTermItem(context, term);
      },
    );
  }

  Widget _buildTermItem(BuildContext context, TextItem term) {
    final statusMatch = RegExp(r'status(\d+)').firstMatch(term.statusClass);
    final status = statusMatch?.group(1) ?? '0';

    final textColor = Theme.of(context).colorScheme.getStatusTextColor(status);
    final backgroundColor = Theme.of(
      context,
    ).colorScheme.getStatusBackgroundColor(status);
    final tooltip = tooltips[term.wordId];

    String? translation;
    String? parentTerm;
    String? parentTranslation;

    if (tooltip != null) {
      translation = tooltip.translation;
      if (tooltip.parents.isNotEmpty) {
        final parent = tooltip.parents.first;
        parentTerm = parent.term;
        parentTranslation = parent.translation;
      }
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => onTermTap?.call(term, details.globalPosition),
          onDoubleTap: () => onTermDoubleTap?.call(term),
          child: Chip(
            backgroundColor: backgroundColor,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  term.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (translation != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '- $translation',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                if (parentTerm != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($parentTerm',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  if (parentTranslation != null) ...[
                    Text(
                      ' - $parentTranslation',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  Text(
                    ')',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        ),
      ),
    );
  }
}
