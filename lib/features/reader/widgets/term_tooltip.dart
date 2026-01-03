import 'dart:async';
import 'package:flutter/material.dart';
import '../models/term_tooltip.dart';

class TermTooltipClass {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static final GlobalKey _tooltipKey = GlobalKey();
  static bool _isHidden = false;

  static void show(
    BuildContext context,
    TermTooltip termTooltip,
    Offset position,
  ) {
    close();

    final screenSize = MediaQuery.of(context).size;
    _isHidden = true;

    _currentEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -9999,
        top: -9999,
        child: Opacity(
          opacity: _isHidden ? 0.0 : 1.0,
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
                  if (termTooltip.parents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...termTooltip.parents.map(
                      (parent) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '(${parent.term})',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(
                                ctx,
                              ).colorScheme.onSurface.withValues(alpha: 1.0),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (parent.translation != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              parent.translation!,
                              style: Theme.of(ctx).textTheme.bodySmall
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(ctx).colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
            child: Opacity(
              opacity: _isHidden ? 0.0 : 1.0,
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
                      if (termTooltip.parents.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...termTooltip.parents.map(
                          (parent) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '(${parent.term})',
                                style: Theme.of(ctx).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(ctx).colorScheme.onSurface
                                          .withValues(alpha: 1.0),
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (parent.translation != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  parent.translation!,
                                  style: Theme.of(ctx).textTheme.bodySmall
                                      ?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(ctx)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
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

  static void makeVisible() {
    if (_currentEntry == null || !_isHidden) return;
    _isHidden = false;
    _currentEntry?.markNeedsBuild();
  }

  static void close() {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;
    _isHidden = false;
  }

  static void _setupAutoDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      close();
    });
  }
}
