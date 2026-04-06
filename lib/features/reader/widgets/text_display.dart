import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/logger/widget_logger.dart';
import '../models/text_item.dart';
import '../models/paragraph.dart';
import '../utils/text_direction_utils.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'term_tooltip.dart';

class TextDisplay extends StatefulWidget {
  final List<Paragraph> paragraphs;
  final void Function(TextItem, BuildContext)? onTap;
  final void Function(TextItem)? onDoubleTap;
  final void Function(TextItem)? onLongPress;
  final VoidCallback? onMultiTermSelectionStart;
  final void Function(List<TextItem>)? onMultiTermSelectionComplete;
  final void Function(TextItem)? onTripleTap;
  final bool enableTripleTap;
  final int doubleTapTimeout;
  final double textSize;
  final double lineSpacing;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool isItalic;
  final ScrollController? scrollController;
  final double topPadding;
  final double bottomPadding;
  final Widget? bottomControlWidget;
  final int? highlightedWordId;
  final int? highlightedParagraphId;
  final int? highlightedOrder;
  final TextDirection? textDirection;

  const TextDisplay({
    super.key,
    required this.paragraphs,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onMultiTermSelectionStart,
    this.onMultiTermSelectionComplete,
    this.onTripleTap,
    this.enableTripleTap = false,
    this.doubleTapTimeout = 300,
    this.textSize = 18.0,
    this.lineSpacing = 1.5,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.normal,
    this.isItalic = false,
    this.scrollController,
    this.topPadding = 0.0,
    this.bottomPadding = 0.0,
    this.bottomControlWidget,
    this.highlightedWordId,
    this.highlightedParagraphId,
    this.highlightedOrder,
    this.textDirection,
  });

  static Widget buildInteractiveWord(
    BuildContext context,
    TextItem item, {
    required double textSize,
    required double lineSpacing,
    required String fontFamily,
    required FontWeight fontWeight,
    required bool isItalic,
    required Key widgetKey,
    void Function(TextItem, BuildContext)? onTap,
    void Function(TextItem)? onDoubleTap,
    void Function(TextItem)? onLongPress,
    void Function(TextItem)? onLongPressStart,
    void Function(TextItem, Offset)? onLongPressMoveUpdate,
    void Function(TextItem)? onLongPressEnd,
    void Function(TextItem)? onTripleTap,
    bool enableTripleTap = false,
    int doubleTapTimeout = 300,
    int? highlightedWordId,
    int? highlightedParagraphId,
    int? highlightedOrder,
    bool isSelected = false,
  }) {
    Color? textColor;
    Color? backgroundColor;

    if (item.wordId != null) {
      final statusMatch = RegExp(r'status(\d+)').firstMatch(item.statusClass);
      final status = statusMatch?.group(1) ?? '0';

      textColor = context.getStatusTextColor(status);
      backgroundColor = context.getStatusBackgroundColor(status);
    }

    final isHighlighted =
        highlightedWordId != null &&
        highlightedWordId == item.wordId &&
        highlightedParagraphId == item.paragraphId &&
        highlightedOrder == item.order;

    final selectionColor = context.multiTermSelectionColor;
    final selectionTextColor = selectionColor.computeLuminance() > 0.5
        ? const Color(0xFF1C1B1F)
        : const Color(0xFFFFFFFF);

    final glowEffect = isHighlighted
        ? BoxShadow(
            color: context.wordGlowColor,
            blurRadius: 12,
            spreadRadius: 3,
            offset: const Offset(0, 0),
          )
        : null;

    final selectionGlow = isSelected
        ? BoxShadow(
            color: selectionColor.withValues(alpha: 0.6),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          )
        : null;

    final textStyle = TextStyle(
      color: isSelected
          ? selectionTextColor
          : textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
      fontWeight: fontWeight,
      fontSize: textSize,
      height: lineSpacing,
      fontFamily: fontFamily,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
    );

    final textWidget = Container(
      padding: backgroundColor != null || isSelected
          ? const EdgeInsets.symmetric(horizontal: 2.0)
          : null,
      decoration: BoxDecoration(
        color: isSelected ? selectionColor : backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: isSelected
            ? Border.all(color: selectionTextColor.withValues(alpha: 0.35))
            : null,
        boxShadow: [
          ...?selectionGlow == null ? null : [selectionGlow],
          ...?glowEffect == null ? null : [glowEffect],
        ],
      ),
      child: Text(item.text, style: textStyle),
    );

    if (item.wordId != null) {
      return RepaintBoundary(
        key: widgetKey,
        child: Builder(
          builder: (context) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap?.call(item, context),
            onLongPress: onLongPressStart == null && onLongPress != null
                ? () => onLongPress(item)
                : null,
            onLongPressStart: onLongPressStart != null
                ? (_) => onLongPressStart(item)
                : null,
            onLongPressMoveUpdate: onLongPressMoveUpdate != null
                ? (details) =>
                      onLongPressMoveUpdate(item, details.globalPosition)
                : null,
            onLongPressEnd: onLongPressEnd != null
                ? (_) => onLongPressEnd(item)
                : null,
            child: textWidget,
          ),
        ),
      );
    }

    return RepaintBoundary(key: widgetKey, child: textWidget);
  }

  @override
  State<TextDisplay> createState() => _TextDisplayState();
}

class _TextDisplayState extends State<TextDisplay> {
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

      _singleTapTimer?.cancel();
      widget.onTap?.call(item, context);

      _singleTapTimer = Timer(
        Duration(milliseconds: widget.doubleTapTimeout),
        () {
          _singleTapTimer = null;
        },
      );
    }
    _lastTappedItem = item;
  }

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    _tripleTapTimer?.cancel();
    super.dispose();
  }

  String _itemKeyId(TextItem item) {
    return '${item.paragraphId}-${item.order}-${item.wordId ?? 'space'}';
  }

  GlobalKey _itemKeyFor(TextItem item) {
    final keyId = _itemKeyId(item);
    return _itemKeys.putIfAbsent(keyId, GlobalKey.new);
  }

  List<TextItem> _allItems() {
    return widget.paragraphs
        .expand((paragraph) => paragraph.textItems)
        .toList();
  }

  List<TextItem> _selectedItems(TextItem start, TextItem end) {
    final startOrder = start.order < end.order ? start.order : end.order;
    final endOrder = start.order > end.order ? start.order : end.order;
    return _allItems()
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
    for (final item in _allItems()) {
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
      'TextDisplay',
      _buildCount,
      'paragraphs: ${widget.paragraphs.length}',
    );
    final fallbackDirection =
        widget.textDirection ?? Directionality.of(context);
    return RepaintBoundary(
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: EdgeInsets.only(
          top: 16 + widget.topPadding,
          left: 16,
          right: 16,
          bottom: 16 + widget.bottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...widget.paragraphs.map((paragraph) {
              return _buildParagraph(context, paragraph, fallbackDirection);
            }),
            if (widget.bottomControlWidget != null) ...[
              const SizedBox(height: 16),
              widget.bottomControlWidget!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(
    BuildContext context,
    Paragraph paragraph,
    TextDirection fallbackDirection,
  ) {
    final textDirection =
        widget.textDirection ??
        TextDirectionUtils.inferFromItems(
          paragraph.textItems,
          fallback: fallbackDirection,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
            children: paragraph.textItems.asMap().entries.map((entry) {
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
