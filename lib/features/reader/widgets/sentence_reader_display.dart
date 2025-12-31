import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../utils/sentence_parser.dart';
import 'text_display.dart';

class SentenceReaderDisplay extends StatelessWidget {
  final CustomSentence? sentence;
  final void Function(TextItem, Offset)? onTap;
  final void Function(TextItem)? onDoubleTap;
  final void Function(TextItem)? onLongPress;
  final double textSize;
  final double lineSpacing;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool isItalic;

  const SentenceReaderDisplay({
    super.key,
    required this.sentence,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.textSize = 18.0,
    this.lineSpacing = 1.5,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.normal,
    this.isItalic = false,
  });

  @override
  Widget build(BuildContext context) {
    if (sentence == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: sentence!.textItems.asMap().entries.map((entry) {
        final item = entry.value;
        return _buildInteractiveWord(context, item);
      }).toList(),
    );
  }

  Widget _buildInteractiveWord(BuildContext context, TextItem item) {
    return TextDisplay.buildInteractiveWord(
      context,
      item,
      textSize: textSize,
      lineSpacing: lineSpacing,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      isItalic: isItalic,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onLongPress: onLongPress,
    );
  }
}
