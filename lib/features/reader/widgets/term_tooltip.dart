import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term_tooltip.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../settings/providers/settings_provider.dart';

String _formatTranslation(String? translation) {
  if (translation == null) return '';

  final lines = translation.split(RegExp(r'[\n\r]+'));

  final result = StringBuffer();
  for (var i = 0; i < lines.length; i++) {
    final trimmedLine = lines[i].trim();
    if (trimmedLine.isEmpty) continue;

    if (result.isNotEmpty) {
      result.write(', ');
    }

    result.write(trimmedLine);
  }

  return result.toString();
}

class _AnimatedTermTooltip extends StatefulWidget {
  final TermTooltip termTooltip;
  final VoidCallback onClose;
  final Offset position;
  final Key? widgetKey;

  const _AnimatedTermTooltip({
    required this.termTooltip,
    required this.onClose,
    required this.position,
    this.widgetKey,
  });

  @override
  State<_AnimatedTermTooltip> createState() => _AnimatedTermTooltipState();
}

class _AnimatedTermTooltipState extends State<_AnimatedTermTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: widget.widgetKey,
      left: widget.position.dx,
      top: widget.position.dy,
      child: GestureDetector(
        onTap: widget.onClose,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _TooltipContent(termTooltip: widget.termTooltip),
          ),
        ),
      ),
    );
  }
}

class _TooltipContent extends ConsumerWidget {
  final TermTooltip termTooltip;

  const _TooltipContent({required this.termTooltip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTooltipImages = ref.watch(
      termFormSettingsProvider.select((settings) => settings.showTooltipImages),
    );

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: context.appColorScheme.background.surface,
          boxShadow: [
            BoxShadow(
              color: context.appColorScheme.text.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: context.appColorScheme.border.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTooltipImages && termTooltip.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _resolveImageUrl(
                      termTooltip.imageUrl!,
                      ref.read(settingsProvider).serverUrl,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              termTooltip.term,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (termTooltip.translation != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTranslation(termTooltip.translation),
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
            if (termTooltip.parents.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...termTooltip.parents.map(
                (parent) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '(${parent.term})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 1.0),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (parent.translation != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatTranslation(parent.translation),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
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
    );
  }
}

String _resolveImageUrl(String imageUrl, String serverUrl) {
  final trimmed = imageUrl.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    return trimmed;
  }

  final normalizedServer = serverUrl.endsWith('/')
      ? serverUrl.substring(0, serverUrl.length - 1)
      : serverUrl;
  final normalizedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$normalizedServer$normalizedPath';
}

class TermTooltipClass {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;
  static final GlobalKey _tooltipKey = GlobalKey();
  static bool _isHidden = false;
  static bool _makeVisibleRequested = false;
  static Offset _tooltipPosition = Offset.zero;

  static void show(
    BuildContext context,
    TermTooltip termTooltip,
    Rect termRect,
  ) {
    close();
    _makeVisibleRequested = false;

    final screenSize = MediaQuery.of(context).size;
    _isHidden = false;

    _currentEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -9999,
        top: -9999,
        child: _AnimatedTermTooltip(
          termTooltip: termTooltip,
          onClose: close,
          position: Offset.zero,
          widgetKey: _tooltipKey,
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

        const verticalOffset = 12.0;
        const horizontalMargin = 8.0;

        double left = termRect.center.dx - tooltipWidth / 2;
        double top = termRect.top - tooltipHeight - verticalOffset;

        if (left < horizontalMargin) {
          left = horizontalMargin;
        } else if (left + tooltipWidth > screenSize.width - horizontalMargin) {
          left = screenSize.width - tooltipWidth - horizontalMargin;
        }

        if (top < 0) {
          top = termRect.bottom + verticalOffset;
        }

        _tooltipPosition = Offset(left, top);

        _currentEntry?.remove();
        _currentEntry = OverlayEntry(
          builder: (ctx) => _AnimatedTermTooltip(
            termTooltip: termTooltip,
            onClose: close,
            position: _tooltipPosition,
            widgetKey: _tooltipKey,
          ),
        );
        Overlay.of(context).insert(_currentEntry!);

        if (_makeVisibleRequested && _isHidden) {
          makeVisible();
        }
      }
    });
    _setupAutoDismiss();
  }

  static void makeVisible() {
    if (_currentEntry == null) {
      _makeVisibleRequested = true;
      return;
    }
    if (!_isHidden) return;
    _isHidden = false;
    _currentEntry?.markNeedsBuild();
  }

  static void close() {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;
    _isHidden = false;
    _makeVisibleRequested = false;
  }

  static void _setupAutoDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      close();
    });
  }
}
