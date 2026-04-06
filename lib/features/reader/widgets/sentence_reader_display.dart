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
  final VoidCallback? onMultiTermSelectionStart;
  final void Function(List<TextItem>)? onMultiTermSelectionComplete;
  final void Function(TextItem)? onTripleTap;
  final bool enableTripleTap;
  final double textSize;
  final double lineSpacing;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool isItalic;
  final int doubleTapTimeout;
  final TextDirection? textDirection;
  final int? highlightedWordId;
  final int? highlightedParagraphId;
  final int? highlightedOrder;

  const SentenceReaderDisplay({
    super.key,
    required this.sentence,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onMultiTermSelectionStart,
    this.onMultiTermSelectionComplete,
    this.onTripleTap,
    this.enableTripleTap = false,
    this.textSize = 18.0,
    this.lineSpacing = 1.5,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.normal,
    this.isItalic = false,
    this.doubleTapTimeout = 300,
    this.textDirection,
    this.highlightedWordId,
    this.highlightedParagraphId,
    this.highlightedOrder,
  });

  @override
  ConsumerState<SentenceReaderDisplay> createState() {
    return _SentenceReaderDisplayState();
  }
}

class _SentenceReaderDisplayState extends ConsumerState<SentenceReaderDisplay> {
  Timer? _singleTapTimer;
  Timer? _tripleTapTimer;
  TextItem? _lastTappedItem;
  TextItem? _selectionStartItem;
  TextItem? _selectionCurrentItem;
  final Map<String, GlobalKey> _itemKeys = {};
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetLogger.logInit('SentenceReaderDisplay');
  }

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    _tripleTapTimer?.cancel();
    super.dispose();
  }

  void _handleTap(TextItem item, BuildContext context) {
    if (_selectionStartItem != null) {
      return;
    }

    if (_lastTappedItem == item &&
        _tripleTapTimer != null &&
        _tripleTapTimer!.isActive) {
      _singleTapTimer?.cancel();
      _tripleTapTimer?.cancel();
      widget.onTripleTap?.call(item);
      TermTooltipClass.close();
      _tripleTapTimer = null;
      _singleTapTimer = null;
    } else if (_lastTappedItem == item &&
        _singleTapTimer != null &&
        _singleTapTimer!.isActive) {
      _singleTapTimer?.cancel();
      TermTooltipClass.close();

      if (widget.enableTripleTap) {
        _tripleTapTimer = Timer(
          Duration(milliseconds: widget.doubleTapTimeout),
          () {
            _tripleTapTimer = null;
            widget.onDoubleTap?.call(item);
            _singleTapTimer = null;
          },
        );
      } else {
        widget.onDoubleTap?.call(item);
        _singleTapTimer = null;
      }
    } else {
      _tripleTapTimer?.cancel();
      _tripleTapTimer = null;

      _lastTappedItem = item;
      _singleTapTimer?.cancel();

      widget.onTap?.call(item, context);

      _singleTapTimer = Timer(
        Duration(milliseconds: widget.doubleTapTimeout),
        () {
          _singleTapTimer = null;
        },
      );
    }
  }

  String _itemKeyId(TextItem item) {
    return '${item.paragraphId}-${item.order}-${item.wordId ?? 'space'}';
  }

  GlobalKey _itemKeyFor(TextItem item) {
    final keyId = _itemKeyId(item);
    return _itemKeys.putIfAbsent(keyId, GlobalKey.new);
  }

  List<TextItem> _selectedItems(TextItem start, TextItem end) {
    final startOrder = start.order < end.order ? start.order : end.order;
    final endOrder = start.order > end.order ? start.order : end.order;
    return widget.sentence!.textItems
        .where((item) => item.order >= startOrder && item.order <= endOrder)
        .toList();
  }

  bool _isSelected(TextItem item) {
    final start = _selectionStartItem;
    final current = _selectionCurrentItem;
    if (start == null || current == null) return false;

    final startOrder = start.order < current.order
        ? start.order
        : current.order;
    final endOrder = start.order > current.order ? start.order : current.order;
    return item.order >= startOrder && item.order <= endOrder;
  }

  TextItem? _findItemAtGlobalPosition(Offset globalPosition) {
    final sentence = widget.sentence;
    if (sentence == null) return null;

    for (final item in sentence.textItems) {
      final itemKey = _itemKeys[_itemKeyId(item)];
      final context = itemKey?.currentContext;
      final renderObject = context?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }

      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      if (rect.contains(globalPosition)) {
        return item;
      }
    }

    return null;
  }

  void _handleSelectionStart(TextItem item) {
    TermTooltipClass.close();
    setState(() {
      _selectionStartItem = item;
      _selectionCurrentItem = item;
    });
    widget.onMultiTermSelectionStart?.call();
  }

  void _handleSelectionMove(TextItem item, Offset globalPosition) {
    if (_selectionStartItem == null) return;
    final hoveredItem = _findItemAtGlobalPosition(globalPosition) ?? item;
    if (_selectionCurrentItem == hoveredItem) return;
    setState(() {
      _selectionCurrentItem = hoveredItem;
    });
  }

  void _handleSelectionEnd(TextItem item) {
    final start = _selectionStartItem;
    final current = _selectionCurrentItem ?? item;
    if (start == null) return;

    final selectedItems = _selectedItems(start, current);
    setState(() {
      _selectionStartItem = null;
      _selectionCurrentItem = null;
    });

    if (widget.onMultiTermSelectionComplete != null) {
      widget.onMultiTermSelectionComplete!(selectedItems);
      return;
    }

    if (selectedItems.length == 1) {
      widget.onLongPress?.call(selectedItems.first);
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
      widgetKey: _itemKeyFor(item),
      onTap: (item, context) => _handleTap(item, context),
      onDoubleTap: (item) => widget.onDoubleTap?.call(item),
      onLongPress: (item) => widget.onLongPress?.call(item),
      onLongPressStart: (item) => _handleSelectionStart(item),
      onLongPressMoveUpdate: (item, globalPosition) =>
          _handleSelectionMove(item, globalPosition),
      onLongPressEnd: (item) => _handleSelectionEnd(item),
      onTripleTap: (item) => widget.onTripleTap?.call(item),
      highlightedWordId: widget.highlightedWordId,
      highlightedParagraphId: widget.highlightedParagraphId,
      highlightedOrder: widget.highlightedOrder,
      isSelected: _isSelected(item),
    );
  }
}
