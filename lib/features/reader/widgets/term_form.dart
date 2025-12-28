import 'package:flutter/material.dart';
import '../models/term_form.dart';

class TermFormWidget extends StatefulWidget {
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
  State<TermFormWidget> createState() => _TermFormWidgetState();
}

class _TermFormWidgetState extends State<TermFormWidget> {
  late TextEditingController _translationController;
  late String _status;
  late TextEditingController _tagsController;
  late TextEditingController _romanizationController;

  @override
  void initState() {
    super.initState();
    _translationController = TextEditingController(
      text: widget.termForm.translation ?? '',
    );
    _status = widget.termForm.status;
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
      status: _status,
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
          const SizedBox(height: 20),
          _buildTermField(context),
          const SizedBox(height: 16),
          _buildTranslationField(context),
          const SizedBox(height: 16),
          _buildStatusField(context),
          const SizedBox(height: 16),
          _buildRomanizationField(context),
          const SizedBox(height: 16),
          _buildTagsField(context),
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
        IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.close),
          tooltip: 'Close',
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
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const [
            DropdownMenuItem(value: '99', child: Text('Well Known')),
            DropdownMenuItem(value: '0', child: Text('Ignored')),
            DropdownMenuItem(value: '1', child: Text('Learning 1')),
            DropdownMenuItem(value: '2', child: Text('Learning 2')),
            DropdownMenuItem(value: '3', child: Text('Learning 3')),
            DropdownMenuItem(value: '4', child: Text('Learning 4')),
            DropdownMenuItem(value: '5', child: Text('Ignored (dotted)')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _status = value;
              });
            }
          },
        ),
      ],
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
