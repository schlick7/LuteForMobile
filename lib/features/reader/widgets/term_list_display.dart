import 'package:flutter/material.dart';
import '../models/text_item.dart';
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

class TermListDisplay extends StatefulWidget {
  final CustomSentence? sentence;
  final void Function(TextItem, Offset)? onTermTap;
  final void Function(TextItem)? onTermDoubleTap;

  const TermListDisplay({
    super.key,
    required this.sentence,
    this.onTermTap,
    this.onTermDoubleTap,
  });

  @override
  State<TermListDisplay> createState() => _TermListDisplayState();
}

class _TermListDisplayState extends State<TermListDisplay> {
  @override
  Widget build(BuildContext context) {
    final uniqueTerms = extractUniqueTerms(widget.sentence);

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

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              widget.onTermTap?.call(term, details.globalPosition),
          onDoubleTap: () => widget.onTermDoubleTap?.call(term),
          child: Chip(
            backgroundColor: backgroundColor?.withValues(alpha: 0.15),
            label: Text(
              term.text,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        ),
      ),
    );
  }
}
