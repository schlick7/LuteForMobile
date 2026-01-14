import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/books/models/book.dart';
import 'package:lute_for_mobile/shared/widgets/status_distribution_bar.dart';
import 'package:lute_for_mobile/app.dart';

class BookCompletionCelebrationDialog extends ConsumerStatefulWidget {
  final Book book;

  const BookCompletionCelebrationDialog({super.key, required this.book});

  @override
  ConsumerState<BookCompletionCelebrationDialog> createState() =>
      _BookCompletionCelebrationDialogState();
}

class _BookCompletionCelebrationDialogState
    extends ConsumerState<BookCompletionCelebrationDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Great Job!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You completed "${widget.book.title}"!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildStatsContainer(context),
                const SizedBox(height: 24),
                _buildPickAnotherButton(context),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Stay Here'),
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            left: -10,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 4,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              createParticlePath: (size) => _drawStar(size),
            ),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3 * pi / 4,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              createParticlePath: (size) => _drawStar(size),
            ),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 4,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              createParticlePath: (size) => _drawStar(size),
            ),
          ),
          Positioned(
            bottom: -10,
            right: -10,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 5 * pi / 4,
              maxBlastForce: 30,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.yellow,
              ],
              createParticlePath: (size) => _drawStar(size),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                icon: Icons.menu_book,
                value: widget.book.wordCount.toString(),
                label: 'Words',
              ),
              _buildStatItem(
                context,
                icon: Icons.layers,
                value: widget.book.totalPages.toString(),
                label: 'Pages',
              ),
              _buildStatItem(
                context,
                icon: Icons.auto_stories,
                value: (widget.book.distinctTerms ?? 0).toString(),
                label: 'Terms',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.book.hasStats) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Term Progress',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            StatusDistributionBar(book: widget.book, showLegend: true),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPickAnotherButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          ref.read(navigationProvider).navigateToScreen('books');
        },
        icon: const Icon(Icons.library_books),
        label: const Text('Pick Another Book'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Path _drawStar(Size size) {
    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;

    path.moveTo(halfWidth, 0);
    path.lineTo(halfWidth + halfWidth * 0.5, halfHeight - halfHeight * 0.3);
    path.lineTo(size.width, halfHeight);
    path.lineTo(halfWidth + halfWidth * 0.3, halfHeight + halfHeight * 0.4);
    path.lineTo(halfWidth + halfWidth * 0.6, size.height);
    path.lineTo(halfWidth, halfHeight + halfHeight * 0.5);
    path.lineTo(halfWidth - halfWidth * 0.6, size.height);
    path.lineTo(halfWidth - halfWidth * 0.3, halfHeight + halfHeight * 0.4);
    path.lineTo(0, halfHeight);
    path.lineTo(halfWidth - halfWidth * 0.5, halfHeight - halfHeight * 0.3);
    path.close();

    return path;
  }
}
