import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../models/paragraph.dart';

class TextDisplay extends StatelessWidget {
  final List<Paragraph> paragraphs;
  final void Function(TextItem)? onTap;

  const TextDisplay({
    super.key,
    required this.paragraphs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs.map((paragraph) {
          return _buildParagraph(context, paragraph);
        }).toList(),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, Paragraph paragraph) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 18,
            height: 1.5,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          children: paragraph.textItems.map((item) {
            return _buildTextSpan(context, item);
          }).toList(),
        ),
      ),
    );
  }

  InlineSpan _buildTextSpan(BuildContext context, TextItem item) {
    final style = TextStyle(
      color: item.isKnown
          ? Colors.green.shade700
          : Theme.of(context).textTheme.bodyLarge?.color,
      fontWeight: item.isKnown ? FontWeight.bold : FontWeight.normal,
    );

    if (item.isSpace) {
      return TextSpan(text: item.text, style: style);
    }

    final recognizer = TapGestureRecognizer();
    recognizer.onTap = () => onTap?.call(item);

    return TextSpan(
      text: item.text,
      style: style,
      recognizer: recognizer,
    );
  }
}
