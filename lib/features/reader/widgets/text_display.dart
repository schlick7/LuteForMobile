import 'dart:async';
import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../models/paragraph.dart';

class TextDisplay extends StatefulWidget {
  final List<Paragraph> paragraphs;
  final void Function(TextItem, Offset)? onTap;
  final void Function(TextItem)? onDoubleTap;

  const TextDisplay({
    super.key,
    required this.paragraphs,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<TextDisplay> createState() => _TextDisplayState();
}

class _TextDisplayState extends State<TextDisplay> {
  Timer? _doubleTapTimer;
  TextItem? _lastTappedItem;

  void _handleTap(TextItem item, Offset position) {
    if (_lastTappedItem == item &&
        _doubleTapTimer != null &&
        _doubleTapTimer!.isActive) {
      _doubleTapTimer?.cancel();
      widget.onDoubleTap?.call(item);
    } else {
      _lastTappedItem = item;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        widget.onTap?.call(item, position);
        _doubleTapTimer = null;
        _lastTappedItem = null;
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.paragraphs.map((paragraph) {
          return _buildParagraph(context, paragraph);
        }).toList(),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, Paragraph paragraph) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        children: paragraph.textItems.asMap().entries.map((entry) {
          final item = entry.value;
          return _buildInteractiveWord(context, item);
        }).toList(),
      ),
    );
  }

  Widget _buildInteractiveWord(BuildContext context, TextItem item) {
    if (item.isSpace) {
      return GestureDetector(
        onTapDown: (details) => _handleTap(item, details.globalPosition),
        child: Text(
          item.text,
          style: TextStyle(
            fontSize: 18,
            height: 1.5,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      );
    }

    final textStyle = TextStyle(
      color: item.isKnown
          ? Colors.green.shade700
          : Theme.of(context).textTheme.bodyLarge?.color,
      fontWeight: item.isKnown ? FontWeight.bold : FontWeight.normal,
      fontSize: 18,
      height: 1.5,
    );

    return GestureDetector(
      onTapDown: (details) => _handleTap(item, details.globalPosition),
      child: Text(item.text, style: textStyle),
    );
  }
}
