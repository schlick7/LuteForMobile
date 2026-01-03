import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../models/term_tooltip.dart';
import '../utils/sentence_parser.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/theme/app_theme.dart';

String _formatTranslation(String? translation) {
  if (translation == null) return '';

  final punctuation = RegExp(r'[.,!?;:，。！？；：]');

  final lines = translation.split('\n');
  final result = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    final trimmedLine = lines[i].trim();
    if (trimmedLine.isEmpty) continue;

    if (result.isNotEmpty) {
      final lastLineIndex = i - 1;
      if (lastLineIndex >= 0) {
        final prevLine = lines[lastLineIndex].trim();
        if (prevLine.isNotEmpty) {
          final lastChar = prevLine[prevLine.length - 1];
          if (!punctuation.hasMatch(lastChar)) {
            result.write(', ');
          } else {
            result.write(' ');
          }
        }
      }
    }

    result.write(trimmedLine);
  }

  return result.toString();
}

List<TextItem> extractUniqueTerms(
  CustomSentence? sentence, {
  bool showKnownTerms = true,
}) {
  if (sentence == null) return [];

  final Map<int, TextItem> uniqueTerms = {};
  for (final item in sentence!.textItems) {
    if (item.wordId != null) {
      final statusMatch = RegExp(r'status(\d+)').firstMatch(item.statusClass);
      final status = statusMatch?.group(1) ?? '0';

      if (status == '98') {
        continue;
      }

      if (!showKnownTerms && status == '99') {
        continue;
      }

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
  final bool showKnownTerms;

  const TermListDisplay({
    super.key,
    required this.sentence,
    this.onTermTap,
    this.onTermDoubleTap,
    required this.tooltips,
    this.showKnownTerms = true,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueTerms = extractUniqueTerms(
      sentence,
      showKnownTerms: showKnownTerms,
    );

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

    final textColor = context.getStatusTextColor(status);
    final backgroundColor = context.getStatusBackgroundColor(status);
    final tooltip = tooltips[term.wordId];

    String? translation;

    if (tooltip != null) {
      translation = _formatTranslation(tooltip.translation);
    }

    final children = <Widget>[
      Text(
        term.text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ];

    if (translation != null) {
      children.add(const SizedBox(width: 4));
      children.add(
        Text(
          '- $translation',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      );
    }

    if (tooltip != null && tooltip.parents.isNotEmpty) {
      children.add(const SizedBox(width: 4));
      children.add(
        Text(
          '(',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      );
      for (var i = 0; i < tooltip.parents.length; i++) {
        final parent = tooltip.parents[i];
        children.add(
          Text(
            parent.term,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        );
        if (parent.translation != null) {
          final formattedParentTranslation = _formatTranslation(
            parent.translation,
          );
          if (formattedParentTranslation.isNotEmpty) {
            children.add(
              Text(
                ' - $formattedParentTranslation',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            );
          }
        }
        if (i < tooltip.parents.length - 1) {
          children.add(
            Text(
              ', ',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          );
        }
      }
      children.add(
        Text(
          ')',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      );
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
            label: Row(mainAxisSize: MainAxisSize.min, children: children),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        ),
      ),
    );
  }
}
