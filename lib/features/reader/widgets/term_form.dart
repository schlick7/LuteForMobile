import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term_form.dart';
import '../models/term_tooltip.dart';
import '../../settings/providers/settings_provider.dart'
    show termFormSettingsProvider;
import '../../../shared/theme/theme_extensions.dart';
import '../../../core/network/content_service.dart';
import 'parent_search.dart';

class TermFormWidget extends ConsumerStatefulWidget {
  final TermForm termForm;
  final void Function(TermForm) onSave;
  final void Function(TermForm) onUpdate;
  final VoidCallback onCancel;
  final ContentService contentService;

  const TermFormWidget({
    super.key,
    required this.termForm,
    required this.onSave,
    required this.onUpdate,
    required this.onCancel,
    required this.contentService,
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
      parents: widget.termForm.parents,
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
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
            const SizedBox(height: 16),
            _buildParentsSection(context),
            const SizedBox(height: 20),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            widget.termForm.term,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
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
            _buildStatusButton(context, '98', '✕', _getStatusColor('98')),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    return Theme.of(context).colorScheme.getStatusColor(status);
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
          color: isSelected
              ? statusColor
              : Theme.of(
                  context,
                ).colorScheme.getStatusColorWithOpacity(statusValue),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor, width: isSelected ? 2 : 1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : statusColor,
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

  Widget _buildParentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Parent Terms',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.termForm.parents.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showAddParentDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Parent'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.termForm.parents.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.account_tree,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No parent terms added',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddParentDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Parent Term'),
                  ),
                ],
              ),
            ),
          ),
        if (widget.termForm.parents.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.termForm.parents.map((parent) {
              return _buildParentChip(context, parent);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildParentChip(BuildContext context, TermParent parent) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parent.term),
          if (parent.translation != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${parent.translation})',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
      avatar: _getParentStatusIcon(context, parent.id),
      onDeleted: () => _removeParent(parent),
    );
  }

  Widget _getParentStatusIcon(BuildContext context, int? parentId) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      child: const Icon(Icons.account_tree, color: Colors.white, size: 14),
    );
  }

  void _showAddParentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Parent Term',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ParentSearchWidget(
                  languageId: widget.termForm.languageId,
                  existingParentIds: widget.termForm.parents
                      .map((p) => p.id)
                      .where((id) => id != null)
                      .cast<int>()
                      .toList(),
                  onParentSelected: (parent) {
                    _addParent(parent);
                    Navigator.of(context).pop();
                  },
                  contentService: widget.contentService,
                  onDone: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addParent(TermParent parent) {
    final updatedForm = widget.termForm.copyWith(
      parents: [...widget.termForm.parents, parent],
    );
    widget.onUpdate(updatedForm);
  }

  void _removeParent(TermParent parent) {
    final updatedForm = widget.termForm.copyWith(
      parents: widget.termForm.parents.where((p) {
        if (parent.id == null || p.id == null) {
          return p.term != parent.term;
        }
        return p.id != parent.id;
      }).toList(),
    );
    widget.onUpdate(updatedForm);
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
