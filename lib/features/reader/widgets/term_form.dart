import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term_form.dart';
import '../models/term_tooltip.dart';
import '../../settings/providers/settings_provider.dart'
    show termFormSettingsProvider;
import '../../../shared/theme/theme_extensions.dart';
import '../../../core/network/content_service.dart';
import '../../../core/network/dictionary_service.dart';
import 'parent_search.dart';
import 'dictionary_view.dart';

class TermFormWidget extends ConsumerStatefulWidget {
  final TermForm termForm;
  final void Function(TermForm) onSave;
  final void Function(TermForm) onUpdate;
  final VoidCallback onCancel;
  final ContentService contentService;
  final void Function(TermParent)? onParentDoubleTap;
  final DictionaryService dictionaryService;
  final VoidCallback? onDismiss;

  const TermFormWidget({
    super.key,
    required this.termForm,
    required this.onSave,
    required this.onUpdate,
    required this.onCancel,
    required this.contentService,
    required this.dictionaryService,
    this.onParentDoubleTap,
    this.onDismiss,
  });

  @override
  ConsumerState<TermFormWidget> createState() => _TermFormWidgetState();
}

class _TermFormWidgetState extends ConsumerState<TermFormWidget> {
  late TextEditingController _translationController;
  late TextEditingController _tagsController;
  late TextEditingController _romanizationController;
  late String _selectedStatus;
  late DictionaryService _dictionaryService;
  bool _isDictionaryOpen = false;
  List<DictionarySource> _dictionaries = [];

  @override
  void initState() {
    super.initState();
    _dictionaryService = widget.dictionaryService;
    _translationController = TextEditingController(
      text: widget.termForm.translation ?? '',
    );
    _romanizationController = TextEditingController(
      text: widget.termForm.romanization ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.termForm.tags?.join(', ') ?? '',
    );
    _selectedStatus = widget.termForm.status;
    _loadDictionaries();
  }

  Future<void> _loadDictionaries() async {
    final languageId = widget.termForm.languageId;
    final dictionaries = await _dictionaryService.getDictionariesForLanguage(
      languageId,
    );
    if (mounted) {
      setState(() {
        _dictionaries = dictionaries;
      });
    }
  }

  @override
  void didUpdateWidget(TermFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.termForm.translation != widget.termForm.translation) {
      _translationController.text = widget.termForm.translation ?? '';
    }
    if (oldWidget.termForm.romanization != widget.termForm.romanization) {
      _romanizationController.text = widget.termForm.romanization ?? '';
    }
    if (oldWidget.termForm.tags != widget.termForm.tags) {
      _tagsController.text = widget.termForm.tags?.join(', ') ?? '';
    }
    if (oldWidget.termForm.status != widget.termForm.status) {
      _selectedStatus = widget.termForm.status;
    }
    if (oldWidget.termForm.parents != widget.termForm.parents) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _translationController.dispose();
    _tagsController.dispose();
    _romanizationController.dispose();
    super.dispose();
  }

  void _updateForm() {
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
    widget.onUpdate(updatedForm);
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
            Row(
              children: [
                const Text('Show Tags'),
                const Spacer(),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: settings.showTags,
                    onChanged: (value) {
                      ref
                          .read(termFormSettingsProvider.notifier)
                          .updateShowTags(value);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Auto Save on Close'),
                const Spacer(),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: settings.autoSave,
                    onChanged: (value) {
                      ref
                          .read(termFormSettingsProvider.notifier)
                          .updateAutoSave(value);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Show Parents in Dictionary'),
                const Spacer(),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: settings.showParentsInDictionary,
                    onChanged: (value) {
                      ref
                          .read(termFormSettingsProvider.notifier)
                          .updateShowParentsInDictionary(value);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
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

  void _toggleDictionary() {
    setState(() {
      _isDictionaryOpen = !_isDictionaryOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(termFormSettingsProvider);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      constraints: _isDictionaryOpen
          ? null
          : const BoxConstraints(maxHeight: 600),
      child: _isDictionaryOpen
          ? Container(
              constraints: BoxConstraints(
                minHeight: 200,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  _buildTranslationField(context),
                  if (settings.showParentsInDictionary) ...[
                    const SizedBox(height: 12),
                    _buildParentsSection(context),
                  ],
                  const SizedBox(height: 12),
                  Expanded(child: _buildDictionaryView(context)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 12),
                    _buildTranslationField(context),
                    const SizedBox(height: 12),
                    _buildStatusField(context),
                    if (widget.termForm.showRomanization) ...[
                      const SizedBox(height: 12),
                      _buildRomanizationField(context),
                    ],
                    if (settings.showTags) ...[
                      const SizedBox(height: 12),
                      _buildTagsField(context),
                    ],
                    const SizedBox(height: 12),
                    _buildParentsSection(context),
                    const SizedBox(height: 16),
                    _buildButtons(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final settings = ref.watch(termFormSettingsProvider);
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
              onPressed: () {
                if (settings.autoSave) {
                  _handleSave();
                } else {
                  widget.onCancel();
                }
              },
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTranslationField(BuildContext context) {
    final accentColor = _isDictionaryOpen
        ? context.customColors.accentButtonColor
        : Theme.of(context).colorScheme.outline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _translationController,
            decoration: InputDecoration(
              labelText: 'Translation',
              labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.customColors.accentLabelColor,
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Enter translation',
              hintStyle: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            maxLines: 2,
            onChanged: (_) => _updateForm(),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          height: 56,
          child: ElevatedButton(
            onPressed: _toggleDictionary,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: _isDictionaryOpen
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Center(child: Icon(Icons.search, size: 28)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusField(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        _buildStatusButton(context, '1', '1', _getStatusColor('1')),
        _buildStatusButton(context, '2', '2', _getStatusColor('2')),
        _buildStatusButton(context, '3', '3', _getStatusColor('3')),
        _buildStatusButton(context, '4', '4', _getStatusColor('4')),
        _buildStatusButton(context, '5', '5', _getStatusColor('5')),
        _buildStatusButton(context, '99', '✓', _getStatusColor('99')),
        _buildStatusButton(context, '98', '✕', _getStatusColor('98')),
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

    final labelColor = !isSelected && statusValue == '5'
        ? _getStatusColor('4')
        : (isSelected ? Theme.of(context).colorScheme.onPrimary : statusColor);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = statusValue;
        });
        _updateForm();
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
              color: labelColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRomanizationField(BuildContext context) {
    return TextFormField(
      controller: _romanizationController,
      decoration: InputDecoration(
        labelText: 'Romanization',
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.customColors.accentLabelColor,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: 'Enter romanization (optional)',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (_) => _updateForm(),
    );
  }

  Widget _buildTagsField(BuildContext context) {
    return TextFormField(
      controller: _tagsController,
      decoration: InputDecoration(
        labelText: 'Tags',
        labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.customColors.accentLabelColor,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: 'Enter tags separated by commas',
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (_) => _updateForm(),
    );
  }

  Widget _buildParentsSection(BuildContext context) {
    final settings = ref.watch(termFormSettingsProvider);
    final isInDictionaryMode =
        _isDictionaryOpen && settings.showParentsInDictionary;

    if (isInDictionaryMode && widget.termForm.parents.isNotEmpty) {
      // When dictionary is open with show parents enabled, show label inline with chips
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parent Terms',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.customColors.accentLabelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.termForm.parents.map((parent) {
                return _buildParentChip(context, parent);
              }).toList(),
            ),
          ),
        ],
      );
    }

    // Default layout: column with label row and chips row
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Parent Terms',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.customColors.accentLabelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isInDictionaryMode)
              Row(
                children: [
                  IconButton(
                    onPressed: widget.termForm.parents.length == 1
                        ? _toggleSyncStatus
                        : null,
                    icon: Icon(
                      widget.termForm.parents.length > 1
                          ? Icons.link_off
                          : Icons.link,
                      color:
                          widget.termForm.parents.length == 1 &&
                              widget.termForm.syncStatus == true
                          ? Colors.green
                          : null,
                    ),
                    tooltip: widget.termForm.parents.length > 1
                        ? 'Cannot sync - multiple parents'
                        : (widget.termForm.syncStatus == true
                              ? 'Sync with parent: ON'
                              : 'Sync with parent: OFF'),
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddParentDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Parent'),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
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
    final status = parent.status?.toString() ?? '0';
    final textColor = Theme.of(context).colorScheme.getStatusTextColor(status);
    final backgroundColor = Theme.of(
      context,
    ).colorScheme.getStatusBackgroundColor(status);

    return GestureDetector(
      onLongPress: () => _showDeleteParentConfirmation(context, parent),
      onDoubleTap: () {
        if (widget.onParentDoubleTap != null) {
          widget.onParentDoubleTap!(parent);
        }
      },
      child: Chip(
        backgroundColor: backgroundColor,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(parent.term, style: TextStyle(color: textColor)),
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
      ),
    );
  }

  void _toggleSyncStatus() {
    if (widget.termForm.parents.length == 1) {
      final updatedForm = widget.termForm.copyWith(
        syncStatus: widget.termForm.syncStatus != true,
      );
      widget.onUpdate(updatedForm);
    }
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
                  contentService: widget.contentService,
                  onParentSelected: (parent) {
                    _addParent(parent);
                  },
                  onDone: () {
                    Navigator.of(context).pop();
                  },
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
      parents: widget.termForm.parents.where((p) => p != parent).toList(),
    );
    widget.onUpdate(updatedForm);
  }

  void _showDeleteParentConfirmation(BuildContext context, TermParent parent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Parent'),
        content: Text('Are you sure you want to unlink from "${parent.term}"?'),
        actions: [
          TextButton(
            onPressed: () {
              _removeParent(parent);
              Navigator.of(context).pop();
            },
            child: const Text('Unlink'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
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

  Widget _buildDictionaryView(BuildContext context) {
    return DictionaryView(
      term: widget.termForm.term,
      dictionaries: _dictionaries,
      languageId: widget.termForm.languageId,
      onClose: _toggleDictionary,
      isVisible: _isDictionaryOpen,
      dictionaryService: _dictionaryService,
    );
  }
}
