import 'dart:async';
import 'package:flutter/material.dart';
import '../models/term_tooltip.dart';

class TermTooltipClass {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static final GlobalKey _tooltipKey = GlobalKey();

  static void show(
    BuildContext context,
    TermTooltip termTooltip,
    Offset position,
  ) {
    close();

    final screenSize = MediaQuery.of(context).size;

    _currentEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: position.dx - 100,
        top: position.dy - 60,
        child: Material(
          key: _tooltipKey,
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  termTooltip.term,
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (termTooltip.translation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    termTooltip.translation!,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(
                        ctx,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentEntry!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox =
          _tooltipKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final tooltipSize = renderBox.size;
        final tooltipWidth = tooltipSize.width;
        final tooltipHeight = tooltipSize.height;

        double top = position.dy - tooltipHeight - 12;
        double left = position.dx - tooltipWidth / 2;

        if (top < 0) {
          top = position.dy + 30;
        }

        if (left < 0) {
          left = 8;
        } else if (left + tooltipWidth > screenSize.width) {
          left = screenSize.width - tooltipWidth - 8;
        }

        _currentEntry?.remove();
        _currentEntry = OverlayEntry(
          builder: (ctx) => Positioned(
            top: top,
            left: left,
            child: Material(
              key: _tooltipKey,
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(
                      ctx,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      termTooltip.term,
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (termTooltip.translation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        termTooltip.translation!,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(
                            ctx,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
        Overlay.of(context).insert(_currentEntry!);
      }
    });
    _setupAutoDismiss();
  }

  static void close() {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void _setupAutoDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      close();
    });
  }
}
