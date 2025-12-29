import 'dart:async';
import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../models/paragraph.dart';
import '../../../shared/theme/theme_extensions.dart';

class TextDisplay extends StatefulWidget {
  final List<Paragraph> paragraphs;
  final void Function(TextItem, Offset)? onTap;
  final void Function(TextItem)? onDoubleTap;
  final double textSize;
  final double lineSpacing;
  final String fontFamily;

  const TextDisplay({
    super.key,
    required this.paragraphs,
    this.onTap,
    this.onDoubleTap,
    this.textSize = 18.0,
    this.lineSpacing = 1.5,
    this.fontFamily = 'Roboto',
  });

  @override
  State<TextDisplay> createState() => _TextDisplayState();
}

class _TextDisplayState extends State<TextDisplay> {
  Timer? _doubleTapTimer;
  TextItem? _lastTappedItem;
  ScrollController? _scrollController;
  double _startY = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  void _handleTap(TextItem item, Offset position) {
    if (_isDragging) return;

    if (_lastTappedItem == item &&
        _doubleTapTimer != null &&
        _doubleTapTimer!.isActive) {
      _doubleTapTimer?.cancel();
      widget.onDoubleTap?.call(item);
      _doubleTapTimer = null;
      _lastTappedItem = null;
    } else {
      _lastTappedItem = item;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        if (!_isDragging) {
          widget.onTap?.call(item, position);
        }
        _doubleTapTimer = null;
        _lastTappedItem = null;
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        _startY = details.globalPosition.dy;
        _isDragging = false;
      },
      onVerticalDragUpdate: (details) {
        final deltaY = details.globalPosition.dy - _startY;
        if (deltaY.abs() > 10 && _scrollController != null) {
          _isDragging = true;
          _scrollController!.jumpTo(_scrollController!.offset - deltaY);
          _startY = details.globalPosition.dy;
        }
      },
      onVerticalDragEnd: (_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _isDragging = false;
        });
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.paragraphs.map((paragraph) {
            return _buildParagraph(context, paragraph);
          }).toList(),
        ),
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
      return Text(
        item.text,
        style: TextStyle(
          fontSize: widget.textSize,
          height: widget.lineSpacing,
          fontFamily: widget.fontFamily,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      );
    }

    Color? textColor;
    Color? backgroundColor;
    FontWeight fontWeight = FontWeight.normal;

    // Extract status number from statusClass (e.g., "status1" -> "1")
    final statusMatch = RegExp(r'status(\d+)').firstMatch(item.statusClass);
    final status = statusMatch?.group(1) ?? '0';

    // Use theme methods for consistent styling
    textColor = Theme.of(context).colorScheme.getStatusTextColor(status);
    backgroundColor = Theme.of(
      context,
    ).colorScheme.getStatusBackgroundColor(status);

    final textStyle = TextStyle(
      color: textColor,
      fontWeight: fontWeight,
      fontSize: widget.textSize,
      height: widget.lineSpacing,
      fontFamily: widget.fontFamily,
      backgroundColor: backgroundColor,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _handleTap(item, details.globalPosition),
      child: Container(
        padding: backgroundColor != null
            ? const EdgeInsets.symmetric(horizontal: 2.0)
            : null,
        decoration: backgroundColor != null
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(2),
              )
            : null,
        child: Text(item.text, style: textStyle),
      ),
    );
  }
}
