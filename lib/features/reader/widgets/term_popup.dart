import 'package:flutter/material.dart';
import '../models/term_popup.dart';

class TermPopupWidget extends StatelessWidget {
  final TermPopup termPopup;
  final VoidCallback onClose;
  final VoidCallback? onEdit;

  const TermPopupWidget({
    super.key,
    required this.termPopup,
    required this.onClose,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildTermSection(context),
          if (termPopup.translation != null) ...[
            const SizedBox(height: 12),
            _buildTranslationSection(context),
          ],
          const SizedBox(height: 12),
          _buildStatusSection(context),
          if (termPopup.sentences.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSentencesSection(context),
          ],
          if (termPopup.parents.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildParentsSection(context),
          ],
          if (termPopup.children.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildChildrenSection(context),
          ],
          if (onEdit != null) ...[
            const SizedBox(height: 16),
            _buildEditButton(context),
          ],
          const SizedBox(height: 8),
          _buildCloseButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Term Details',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildTermSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Term',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          termPopup.term,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTranslationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Translation',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          termPopup.translation!,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(
          context,
          termPopup.status,
        ).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(context, termPopup.status),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(termPopup.status),
            size: 20,
            color: _getStatusColor(context, termPopup.status),
          ),
          const SizedBox(width: 8),
          Text(
            termPopup.statusLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _getStatusColor(context, termPopup.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sentences',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...termPopup.sentences.map((sentence) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    sentence,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildParentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parent Terms',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: termPopup.parents.map((parent) {
            return Chip(
              label: Text(parent.term),
              avatar: parent.translation != null
                  ? Text(
                      parent.translation!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    )
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChildrenSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Terms',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: termPopup.children.map((child) {
            return Chip(
              label: Text(child.term),
              avatar: child.translation != null
                  ? Text(
                      child.translation!.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    )
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onEdit,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Term'),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(onPressed: onClose, child: const Text('Close')),
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
