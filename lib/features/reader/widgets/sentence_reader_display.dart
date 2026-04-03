import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger/widget_logger.dart';
import '../models/text_item.dart';
import '../utils/sentence_parser.dart';
import '../utils/text_direction_utils.dart';
import 'text_display.dart';
import 'term_tooltip.dart';

class SentenceReaderDisplay extends ConsumerStatefulWidget {
  final CustomSentence? sentence;
  final void Function(TextItem, BuildContext)? onTap;
  final void Function(TextItem)? onDoubleTap;
  final void Function(TextItem)? onLongPress;
  final double textSize;
  final double lineSpacing;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool isItalic;
  final int doubleTapTimeout;
  final TextDirection? textDirection;

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
    this.doubleTapTimeout = 300,
    this.textDirection,
  });

  @override
  ConsumerState<SentenceReaderDisplay> createState() {
    return _SentenceReaderDisplayState();
  }
}

class _SentenceReaderDisplayState extends ConsumerState<SentenceReaderDisplay> {
  Timer? _doubleTapTimer;
  TextItem? _lastTappedItem;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetLogger.logInit('SentenceReaderDisplay');
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _handleTap(TextItem item, BuildContext context) {
    if (_lastTappedItem == item &&
        _doubleTapTimer != null &&
        _doubleTapTimer!.isActive) {
      _doubleTapTimer?.cancel();
      TermTooltipClass.close();
      widget.onDoubleTap?.call(item);
      _doubleTapTimer = null;
      _lastTappedItem = null;
    } else {
      _lastTappedItem = item;
      _doubleTapTimer?.cancel();

      widget.onTap?.call(item, context);

      _doubleTapTimer = Timer(
        Duration(milliseconds: widget.doubleTapTimeout),
        () {
          _doubleTapTimer = null;
          _lastTappedItem = null;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    WidgetLogger.logRebuild(
      'SentenceReaderDisplay',
      _buildCount,
      'sentence ${widget.sentence?.id ?? "null"}',
    );
    if (widget.sentence == null) return const SizedBox.shrink();

    final textDirection =
        widget.textDirection ??
        TextDirectionUtils.inferFromItems(
          widget.sentence!.textItems,
          fallback: Directionality.of(context),
        );

    return RepaintBoundary(
      child: Directionality(
        textDirection: textDirection,
        child: Align(
          alignment: textDirection == TextDirection.rtl
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Wrap(
            spacing: 0,
            runSpacing: 0,
            textDirection: textDirection,
            children: widget.sentence!.textItems.asMap().entries.map((entry) {
              final item = entry.value;
              return _buildInteractiveWord(context, item);
            }).toList(),
          ),
        ),
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
      onTap: (item, context) => _handleTap(item, context),
      onDoubleTap: (item) => widget.onDoubleTap?.call(item),
      onLongPress: (item) => widget.onLongPress?.call(item),
    );
  }
}
