import 'dart:async';
import 'package:flutter/material.dart';
import '../models/term_popup.dart';

class TermTooltipClass {
  static void show(BuildContext context, TermPopup termPopup, Offset position) {
    try {
      _showInternal(context, termPopup, position);
    } catch (e) {
      return;
    }
  }

  static void _showInternal(
    BuildContext context,
    TermPopup termPopup,
    Offset position,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final tooltipWidth = 200.0;

    double top = position.dy - 80.0 - 8;
    double left = position.dx - tooltipWidth / 2;

    if (top < 0) {
      top = position.dy + 30;
    }

    if (left < 0) {
      left = 8;
    } else if (left + tooltipWidth > screenSize.width) {
      left = screenSize.width - tooltipWidth - 8;
    }

    _setupAutoDismiss(context);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (ctx) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(ctx).pop(),
                excludeFromSemantics: true,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: top,
              left: left,
              child: Material(
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
                        termPopup.term,
                        style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (termPopup.translation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          termPopup.translation!,
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
          ],
        );
      },
    );
  }

  static void _setupAutoDismiss(BuildContext context) {
    Timer(const Duration(seconds: 5), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
}
