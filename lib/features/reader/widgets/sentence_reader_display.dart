import 'dart:async';
import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../utils/sentence_parser.dart';
import 'text_display.dart';
import 'term_tooltip.dart';

class SentenceReaderDisplay extends StatefulWidget {
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
  State<SentenceReaderDisplay> createState() => _SentenceReaderDisplayState();
}

class _SentenceReaderDisplayState extends State<SentenceReaderDisplay> {
  Timer? _doubleTapTimer;
  TextItem? _lastTappedItem;

  void _handleTap(TextItem item, Offset tapPosition) {
    if (_lastTappedItem == item &&
        _doubleTapTimer != null &&
        _doubleTapTimer!.isActive) {
      _doubleTapTimer?.cancel();
      widget.onDoubleTap?.call(item);
      _doubleTapTimer = null;
      _lastTappedItem = null;
      TermTooltipClass.close();
    } else {
      _lastTappedItem = item;
      _doubleTapTimer?.cancel();

      widget.onTap?.call(item, tapPosition);

      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        TermTooltipClass.makeVisible();
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
    if (widget.sentence == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        children: widget.sentence!.textItems.asMap().entries.map((entry) {
          final item = entry.value;
          return _buildInteractiveWord(context, item);
        }).toList(),
      ),
    );
  }

  Widget _buildInteractiveWord(BuildContext context, TextItem item) {
    return TextDisplay.buildInteractiveWord(
      context,
      item,
      textSize: widget.textSize,
      lineSpacing: widget.lineSpacing,
      fontFamily: widget.fontFamily,
      fontWeight: widget.fontWeight,
      isItalic: widget.isItalic,
      onTap: (item, position) => _handleTap(item, position),
      onDoubleTap: (item) => widget.onDoubleTap?.call(item),
      onLongPress: (item) => widget.onLongPress?.call(item),
    );
  }
}
