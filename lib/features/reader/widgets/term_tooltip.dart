import 'dart:async';
import 'package:flutter/material.dart';
import '../models/term_popup.dart';

class TermTooltip extends StatefulWidget {
  final TermPopup termPopup;
  final VoidCallback onDismiss;
  final Offset position;

  const TermTooltip({
    super.key,
    required this.termPopup,
    required this.onDismiss,
    required this.position,
  });

  @override
  State<TermTooltip> createState() => _TermTooltipState();
}

class _TermTooltipState extends State<TermTooltip> {
  final _containerKey = GlobalKey();
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _setupAutoDismiss();
  }

  void _setupAutoDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final tooltipWidth = 200.0;
    final tooltipHeight = widget.termPopup.translation != null ? 120.0 : 80.0;

    double top = widget.position.dy - tooltipHeight - 8;
    double left = widget.position.dx - tooltipWidth / 2;

    if (top < 0) {
      top = widget.position.dy + 30;
    }

    if (left < 0) {
      left = 8;
    } else if (left + tooltipWidth > screenSize.width) {
      left = screenSize.width - tooltipWidth - 8;
    }

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Material(
          color: Colors.transparent,
          child: Container(
            key: _containerKey,
            constraints: const BoxConstraints(maxWidth: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Theme.of(
                  context,
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
                  widget.termPopup.term,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.termPopup.translation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.termPopup.translation!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(widget.termPopup.status),
                      size: 14,
                      color: _getStatusColor(context, widget.termPopup.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.termPopup.statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(
                          context,
                          widget.termPopup.status,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case '99':
        return Colors.green.shade700;
      case '0':
        return Colors.blue.shade600;
      case '1':
        return Colors.pink.shade700;
      case '2':
        return Colors.orange.shade700;
      case '3':
        return Colors.amber.shade700;
      case '4':
        return Colors.grey.shade600;
      case '5':
        return Colors.grey.shade400;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case '99':
        return Icons.check_circle;
      case '0':
        return Icons.block;
      case '1':
        return Icons.school;
      case '2':
        return Icons.auto_stories;
      case '3':
        return Icons.menu_book;
      case '4':
        return Icons.book;
      default:
        return Icons.help_outline;
    }
  }
}
