import 'dart:async';
import 'package:flutter/material.dart';
import '../models/text_item.dart';
import '../models/paragraph.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'term_tooltip.dart';

class TextDisplay extends StatefulWidget {
  final List<Paragraph> paragraphs;
  final void Function(TextItem, Offset)? onTap;
  final void Function(TextItem)? onDoubleTap;
  final void Function(TextItem)? onLongPress;
  final double textSize;
  final double lineSpacing;
  final String fontFamily;
  final FontWeight fontWeight;
  final bool isItalic;

  const TextDisplay({
    super.key,
    required this.paragraphs,
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
  State<TextDisplay> createState() => _TextDisplayState();
}

class _TextDisplayState extends State<TextDisplay> {
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
      return Text(
        item.text,
        style: TextStyle(
          fontSize: widget.textSize,
          height: widget.lineSpacing,
          fontFamily: widget.fontFamily,
          fontWeight: widget.fontWeight,
          fontStyle: widget.isItalic ? FontStyle.italic : FontStyle.normal,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      );
    }

    Color? textColor;
    Color? backgroundColor;
    FontWeight fontWeight = widget.fontWeight;

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
      fontStyle: widget.isItalic ? FontStyle.italic : FontStyle.normal,
      backgroundColor: backgroundColor,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _handleTap(item, details.globalPosition),
      onLongPress: () => widget.onLongPress?.call(item),
      child: Container(
        padding: backgroundColor != null
            ? const EdgeInsets.symmetric(horizontal: 2.0)
            : null,
        decoration: backgroundColor != null
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Text(item.text, style: textStyle),
      ),
    );
  }
}
