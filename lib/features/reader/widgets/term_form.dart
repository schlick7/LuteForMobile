import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term_form.dart';
import '../../settings/providers/settings_provider.dart'
    show termFormSettingsProvider;

class TermFormWidget extends ConsumerStatefulWidget {
  final TermForm termForm;
  final void Function(TermForm) onSave;
  final VoidCallback onCancel;

  const TermFormWidget({
    super.key,
    required this.termForm,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<TermFormWidget> createState() => _TermFormWidgetState();
}

class _TermFormWidgetState extends ConsumerState<TermFormWidget> {
  late TextEditingController _translationController;
  late TextEditingController _tagsController;
  late TextEditingController _romanizationController;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _translationController = TextEditingController(
      text: widget.termForm.translation ?? '',
    );
    _selectedStatus = widget.termForm.status;
    _tagsController = TextEditingController(
      text: widget.termForm.tags?.join(', ') ?? '',
    );
    _romanizationController = TextEditingController(
      text: widget.termForm.romanization ?? '',
    );
  }

  @override
  void dispose() {
    _translationController.dispose();
    _tagsController.dispose();
    _romanizationController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final updatedForm = widget.termForm.copyWith(
      translation: _translationController.text.trim(),
      status: _selectedStatus,
      tags: _tagsController.text
          .trim()
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      romanization: _romanizationController.text.trim(),
    );
    widget.onSave(updatedForm);
  }

  void _showSettingsMenu() {
    final settings = ref.watch(termFormSettingsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Term Form Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Show Romanization'),
              value: settings.showRomanization,
              onChanged: (value) {
                ref
                    .read(termFormSettingsProvider.notifier)
                    .updateShowRomanization(value);
                Navigator.of(context).pop();
              },
            ),
            SwitchListTile(
              title: const Text('Show Tags'),
              value: settings.showTags,
              onChanged: (value) {
                ref
                    .read(termFormSettingsProvider.notifier)
                    .updateShowTags(value);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(termFormSettingsProvider);
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
          const SizedBox(height: 20),
          _buildTermField(context),
          const SizedBox(height: 16),
          _buildTranslationField(context),
          const SizedBox(height: 16),
          _buildStatusField(context),
          if (settings.showRomanization) ...[
            const SizedBox(height: 16),
            _buildRomanizationField(context),
          ],
          if (settings.showTags) ...[
            const SizedBox(height: 16),
            _buildTagsField(context),
          ],
          if (widget.termForm.dictionaries.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDictionariesSection(context),
          ],
          const SizedBox(height: 20),
          _buildButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Edit Term',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _showSettingsMenu,
              icon: const Icon(Icons.settings),
              tooltip: 'Term Form Settings',
            ),
            IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermField(BuildContext context) {
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
        const SizedBox(height: 8),
        TextFormField(
          initialValue: widget.termForm.term,
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTranslationField(BuildContext context) {
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
        const SizedBox(height: 8),
        TextFormField(
          controller: _translationController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Enter translation',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildStatusField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildStatusButton(context, '1', '1', _getStatusColor('1')),
            _buildStatusButton(context, '2', '2', _getStatusColor('2')),
            _buildStatusButton(context, '3', '3', _getStatusColor('3')),
            _buildStatusButton(context, '4', '4', _getStatusColor('4')),
            _buildStatusButton(context, '5', '5', _getStatusColor('5')),
            _buildStatusButton(context, '99', '✓', _getStatusColor('99')),
            _buildStatusButton(context, '0', '✕', _getStatusColor('0')),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFFb46b7a);
      case '2':
        return const Color(0xFFBA8050);
      case '3':
        return const Color(0xFFBD9C7B);
      case '4':
        return const Color(0xFF756D6B);
      case '5':
        return Colors.grey.shade400;
      case '99':
        return const Color(0xFF419252);
      case '0':
        return const Color(0xFF8095FF);
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusButton(
    BuildContext context,
    String statusValue,
    String label,
    Color statusColor,
  ) {
    final isSelected = _selectedStatus == statusValue;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = statusValue;
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? statusColor : statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor, width: isSelected ? 2 : 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : statusColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRomanizationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Romanization',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _romanizationController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Enter romanization (optional)',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _tagsController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Enter tags separated by commas',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDictionariesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dictionaries',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.termForm.dictionaries.map((dict) {
            return Chip(
              label: Text(dict),
              avatar: const Icon(Icons.book, size: 18),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
