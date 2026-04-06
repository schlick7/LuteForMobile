import 'dart:convert';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term_form.dart';
import '../models/term_tooltip.dart';
import '../../settings/providers/settings_provider.dart'
    show settingsProvider, termFormSettingsProvider;
import '../../settings/models/ai_settings.dart';
import '../../settings/providers/ai_settings_provider.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../core/network/content_service.dart';
import '../../../core/network/dictionary_service.dart';
import '../providers/sentence_tts_provider.dart';
import '../../../core/providers/ai_provider.dart';
import 'parent_search.dart';
import 'dictionary_view.dart';
import '../providers/current_book_provider.dart';

class TermFormWidget extends ConsumerStatefulWidget {
  final TermForm termForm;
  final String? sentence;
  final String? initialReaderStatus;
  final void Function(TermForm) onSave;
  final void Function(TermForm) onUpdate;
  final VoidCallback onCancel;
  final ContentService contentService;
  final void Function(TermParent)? onParentDoubleTap;
  final DictionaryService dictionaryService;
  final VoidCallback? onDismiss;
  final void Function(bool)? onDictionaryToggle;
  final void Function(int langId)? onStatus99Changed;

  const TermFormWidget({
    super.key,
    required this.termForm,
    this.sentence,
    this.initialReaderStatus,
    required this.onSave,
    required this.onUpdate,
    required this.onCancel,
    required this.contentService,
    required this.dictionaryService,
    this.onParentDoubleTap,
    this.onDismiss,
    this.onDictionaryToggle,
    this.onStatus99Changed,
  });

  @override
  ConsumerState<TermFormWidget> createState() => _TermFormWidgetState();
}

class _TermFormWidgetState extends ConsumerState<TermFormWidget> {
  late TextEditingController _translationController;
  late TextEditingController _romanizationController;
  late String _selectedStatus;
  late DictionaryService _dictionaryService;
  String? _currentImageUrl;
  String? _currentImageFilename;
  bool _isDictionaryOpen = false;
  List<DictionarySource> _dictionaries = [];
  bool _isLoadingAITranslation = false;
  bool _isSavingImage = false;
  StateSetter? _imageDialogSetState;
  List<String> _pendingAITranslations = [];
  String? _lastAutoFetchedTermKey;

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
    _selectedStatus = widget.termForm.status;
    _currentImageUrl = widget.termForm.imageUrl;
    _currentImageFilename = widget.termForm.imageFilename;
    _loadDictionaries();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeAutoFetchAITranslation();
    });
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
    if (oldWidget.termForm.translation != widget.termForm.translation &&
        _translationController.text != (widget.termForm.translation ?? '')) {
      _translationController.text = widget.termForm.translation ?? '';
    }
    if (oldWidget.termForm.romanization != widget.termForm.romanization &&
        _romanizationController.text != (widget.termForm.romanization ?? '')) {
      _romanizationController.text = widget.termForm.romanization ?? '';
    }
    if (oldWidget.termForm.status != widget.termForm.status) {
      _selectedStatus = widget.termForm.status;
    }
    if (oldWidget.termForm.imageUrl != widget.termForm.imageUrl ||
        oldWidget.termForm.imageFilename != widget.termForm.imageFilename) {
      _currentImageUrl = widget.termForm.imageUrl;
      _currentImageFilename = widget.termForm.imageFilename;
    }
    if (oldWidget.termForm.parents != widget.termForm.parents) {
      setState(() {});
    }
    if (oldWidget.termForm.term != widget.termForm.term ||
        oldWidget.termForm.termId != widget.termForm.termId ||
        oldWidget.termForm.status != widget.termForm.status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeAutoFetchAITranslation();
      });
    }
  }

  @override
  void dispose() {
    _translationController.dispose();
    _romanizationController.dispose();
    super.dispose();
  }

  void _updateForm() {
    final updatedForm = widget.termForm.copyWith(
      translation: _translationController.text.trim(),
      status: _selectedStatus,
      romanization: _romanizationController.text.trim(),
      parents: widget.termForm.parents,
    );
    widget.onUpdate(updatedForm);
  }

  List<String> _splitTranslations(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _addPendingTranslationToField(String translation) {
    final currentTranslations = _splitTranslations(_translationController.text);
    if (!currentTranslations.contains(translation)) {
      currentTranslations.add(translation);
      _translationController.text = currentTranslations.join(', ');
      _updateForm();
    }

    setState(() {
      _pendingAITranslations = _pendingAITranslations
          .where((item) => item != translation)
          .toList();
    });
  }

  void _maybeAutoFetchAITranslation() {
    if (!mounted || _isLoadingAITranslation) return;

    final settings = ref.read(termFormSettingsProvider);
    final aiSettings = ref.read(aiSettingsProvider);
    final termConfig = aiSettings.promptConfigs[AIPromptType.termTranslation];
    final shouldShowAI =
        aiSettings.provider != AIProvider.none && termConfig?.enabled == true;
    final effectiveStatus =
        widget.initialReaderStatus ?? widget.termForm.status;

    if (!settings.autoFetchAITranslationsForStatus0 ||
        !shouldShowAI ||
        effectiveStatus != '0') {
      return;
    }

    final termKey =
        '${widget.termForm.termId ?? 'new'}:${widget.termForm.term}:$effectiveStatus';
    if (_lastAutoFetchedTermKey == termKey) return;

    _lastAutoFetchedTermKey = termKey;
    _fetchAITranslation();
  }

  void _handleSave() {
    final newStatus = _selectedStatus;
    final oldStatus = widget.termForm.status;

    final updatedForm = widget.termForm.copyWith(
      translation: _translationController.text.trim(),
      status: newStatus,
      romanization: _romanizationController.text.trim(),
      parents: widget.termForm.parents,
    );

    if (oldStatus != '99' && newStatus == '99') {
      widget.onStatus99Changed?.call(widget.termForm.languageId);
    }

    widget.onSave(updatedForm);
  }

  void _showSettingsMenu() {
    final settings = ref.watch(termFormSettingsProvider);
    final aiSettings = ref.watch(aiSettingsProvider);
    final termConfig = aiSettings.promptConfigs[AIPromptType.termTranslation];
    final shouldShowAIOption =
        aiSettings.provider != AIProvider.none && termConfig?.enabled == true;
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
                const Text('Show Images'),
                const Spacer(),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: settings.showImages,
                    onChanged: (value) {
                      ref
                          .read(termFormSettingsProvider.notifier)
                          .updateShowImages(value);
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
            if (shouldShowAIOption)
              Row(
                children: [
                  const Text('Auto Add AI Translations'),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: settings.autoAddAITranslations,
                      onChanged: (value) {
                        ref
                            .read(termFormSettingsProvider.notifier)
                            .updateAutoAddAITranslations(value);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            if (shouldShowAIOption)
              Row(
                children: [
                  const Text('Auto Fetch for Status 0'),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: settings.autoFetchAITranslationsForStatus0,
                      onChanged: (value) {
                        ref
                            .read(termFormSettingsProvider.notifier)
                            .updateAutoFetchAITranslationsForStatus0(value);
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
      widget.onDictionaryToggle?.call(_isDictionaryOpen);
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
                color: context.appColorScheme.background.background,
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
                  color: context.appColorScheme.background.background,
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
                      _buildTagsSection(context),
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

  void _showEditTermDialog(BuildContext context) {
    final TextEditingController termEditController = TextEditingController(
      text: widget.termForm.term,
    );

    bool canSave(String newText) {
      if (newText.length != widget.termForm.term.length) {
        return false;
      }
      if (newText.toLowerCase() != widget.termForm.term.toLowerCase()) {
        return false;
      }
      return true;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Term Capitalization'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You can only change the capitalization of letters. '
                  'The number of characters must remain the same.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: termEditController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Term',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: canSave(termEditController.text)
                        ? null
                        : 'Capitalization only - same characters and length',
                  ),
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  termEditController.text = termEditController.text
                      .toLowerCase();
                  setDialogState(() {});
                },
                child: const Icon(Icons.format_size),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: canSave(termEditController.text)
                    ? () {
                        final updatedForm = widget.termForm.copyWith(
                          term: termEditController.text,
                        );
                        widget.onUpdate(updatedForm);
                        Navigator.of(dialogContext).pop();
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final settings = ref.watch(termFormSettingsProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPress: () => _showEditTermDialog(context),
                  child: Text(
                    widget.termForm.term,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, child) {
                  final ttsState = ref.watch(sentenceTTSProvider);
                  final isCurrentTerm =
                      ttsState.currentText == widget.termForm.term;

                  IconData icon;
                  Color color;
                  VoidCallback? onPressed;

                  if (isCurrentTerm && ttsState.isLoading) {
                    icon = Icons.hourglass_empty;
                    color = context.m3Primary;
                    onPressed = null;
                  } else if (isCurrentTerm && ttsState.isPlaying) {
                    icon = Icons.stop;
                    color = context.error;
                    onPressed = () =>
                        ref.read(sentenceTTSProvider.notifier).stop();
                  } else {
                    icon = Icons.volume_up;
                    color = context.m3Primary;
                    onPressed = () => ref
                        .read(sentenceTTSProvider.notifier)
                        .speakSentence(widget.termForm.term, 0);
                  }

                  return IconButton(
                    icon: Icon(icon),
                    color: color,
                    onPressed: onPressed,
                    tooltip: isCurrentTerm && ttsState.isPlaying
                        ? 'Stop TTS'
                        : 'Read term',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  );
                },
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (settings.showImages) ...[
              _buildImageButton(context),
              const SizedBox(width: 4),
            ],
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
        ? context.m3Primary
        : context.appColorScheme.border.outline;
    final settings = ref.watch(termFormSettingsProvider);

    final aiSettings = ref.watch(aiSettingsProvider);
    final termConfig = aiSettings.promptConfigs[AIPromptType.termTranslation];
    final shouldShowAI =
        aiSettings.provider != AIProvider.none && termConfig?.enabled == true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!settings.autoAddAITranslations &&
                  _pendingAITranslations.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _pendingAITranslations.map((translation) {
                      return ActionChip(
                        avatar: const Icon(Icons.add_circle_outline, size: 18),
                        label: Text(translation),
                        onPressed: () =>
                            _addPendingTranslationToField(translation),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),
              ],
              TextFormField(
                controller: _translationController,
                decoration: InputDecoration(
                  labelText: 'Translation',
                  labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.m3Secondary,
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
                onChanged: (_) => setState(_updateForm),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (shouldShowAI)
          SizedBox(
            width: 56,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoadingAITranslation ? null : _fetchAITranslation,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.m3Primary,
                foregroundColor: context.appColorScheme.text.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: _isLoadingAITranslation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          context.appColorScheme.text.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.psychology, size: 28),
            ),
          ),
        if (shouldShowAI) const SizedBox(width: 4),
        SizedBox(
          width: 56,
          height: 56,
          child: ElevatedButton(
            onPressed: _toggleDictionary,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: _isDictionaryOpen
                  ? context.appColorScheme.text.onPrimary
                  : context.appColorScheme.text.primary,
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

  Future<void> _fetchAITranslation() async {
    if (_isLoadingAITranslation) return;

    setState(() {
      _isLoadingAITranslation = true;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final currentBookState = ref.read(currentBookProvider);
      final language =
          currentBookState.languageName ??
          currentBookState.book?.language ??
          'Unknown';

      final translation = await aiService.translateTerm(
        widget.termForm.term,
        language,
        sentence: widget.sentence,
      );
      final cleanTranslations = _splitTranslations(
        translation.replaceAll('\n', ' '),
      );

      if (ref.read(termFormSettingsProvider).autoAddAITranslations) {
        final currentTranslations = _splitTranslations(
          _translationController.text,
        );
        for (final item in cleanTranslations) {
          if (!currentTranslations.contains(item)) {
            currentTranslations.add(item);
          }
        }
        _translationController.text = currentTranslations.join(', ');
        _updateForm();
      } else {
        final existingTranslations = _splitTranslations(
          _translationController.text,
        );
        setState(() {
          _pendingAITranslations = cleanTranslations
              .where((item) => !existingTranslations.contains(item))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI translation failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAITranslation = false;
        });
      }
    }
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
    return context.getStatusColor(status);
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
        : (isSelected ? context.appColorScheme.text.onPrimary : statusColor);

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
              : context.getStatusColorWithOpacity(statusValue),
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
          color: context.m3Secondary,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        hintText: 'Enter romanization (optional)',
        hintStyle: TextStyle(
          color: context.appColorScheme.text.primary.withValues(alpha: 0.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (_) => _updateForm(),
    );
  }

  Widget _buildImageButton(BuildContext context) {
    final resolvedImageUrl = _resolveImageUrl(_currentImageUrl);
    return IconButton(
      onPressed: _showImageManagerDialog,
      tooltip: 'Manage image',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: context.appColorScheme.border.outline),
              borderRadius: BorderRadius.circular(6),
              color: context.appColorScheme.background.surface,
            ),
            child: resolvedImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      resolvedImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildSmallImagePlaceholder(context);
                      },
                    ),
                  )
                : _buildSmallImagePlaceholder(context),
          ),
          if (_isSavingImage)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 12,
                height: 12,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: context.appColorScheme.background.surface,
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  void _showImageManagerDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          _imageDialogSetState = setDialogState;
          return AlertDialog(
            title: const Text('Term Image'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.appColorScheme.border.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _currentImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                _resolveImageUrl(_currentImageUrl!)!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildImagePlaceholder(context);
                                },
                              ),
                            ),
                          )
                        : _buildImagePlaceholder(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentImageFilename?.isNotEmpty == true
                        ? _currentImageFilename!
                        : 'No image attached',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed:
                            (_isSavingImage || _currentImageFilename == null)
                            ? null
                            : _removeImage,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSavingImage ? null : _pickAndUploadImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSavingImage
                            ? null
                            : () => _showImageUrlDialog(dialogContext),
                        icon: const Icon(Icons.link),
                        label: const Text('From URL'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isSavingImage
                            ? null
                            : () => _showImageSearchDialog(dialogContext),
                        icon: const Icon(Icons.image_search),
                        label: const Text('Search'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _imageDialogSetState = null;
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmallImagePlaceholder(BuildContext context) {
    return Icon(
      Icons.image_outlined,
      size: 16,
      color: context.m3Secondary.withValues(alpha: 0.8),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appColorScheme.background.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 56,
        color: context.m3Secondary.withValues(alpha: 0.8),
      ),
    );
  }

  String? _resolveImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = imageUrl.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return trimmed;
    }

    final serverUrl = ref.read(settingsProvider).serverUrl.trim();
    if (serverUrl.isEmpty) {
      return trimmed;
    }

    final normalizedServer = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    final normalizedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$normalizedServer$normalizedPath';
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }

    await _saveImage(
      operation: () => widget.contentService.uploadTermImage(
        widget.termForm.languageId,
        widget.termForm.term,
        path,
      ),
      successMessage: 'Image uploaded',
    );
  }

  void _showImageUrlDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Image From URL'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
          ),
          keyboardType: TextInputType.url,
          onSubmitted: (_) async {
            final imageUrl = controller.text.trim();
            if (imageUrl.isEmpty) return;
            Navigator.of(dialogContext).pop();
            await _saveImage(
              operation: () => widget.contentService.saveTermImageFromUrl(
                widget.termForm.languageId,
                widget.termForm.term,
                imageUrl,
              ),
              successMessage: 'Image saved',
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final imageUrl = controller.text.trim();
              if (imageUrl.isEmpty) return;
              Navigator.of(dialogContext).pop();
              await _saveImage(
                operation: () => widget.contentService.saveTermImageFromUrl(
                  widget.termForm.languageId,
                  widget.termForm.term,
                  imageUrl,
                ),
                successMessage: 'Image saved',
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showImageSearchDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.termForm.term);
    List<TermImageSearchResult> results = const [];
    String? errorMessage;
    bool isLoading = false;
    bool initialSearchTriggered = false;

    Future<void> runSearch(StateSetter setDialogState) async {
      final query = controller.text.trim();
      if (query.isEmpty) {
        setDialogState(() {
          errorMessage = 'Enter a search query';
          results = const [];
        });
        return;
      }

      setDialogState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final searchResults = await widget.contentService.searchTermImages(
          widget.termForm.languageId,
          query,
          '',
        );

        setDialogState(() {
          results = searchResults;
          if (searchResults.isEmpty) {
            errorMessage = 'No images found';
          }
        });
      } catch (e) {
        setDialogState(() {
          errorMessage = _extractErrorMessage(e);
          results = const [];
        });
      } finally {
        setDialogState(() {
          isLoading = false;
        });
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (!initialSearchTriggered) {
            initialSearchTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) {
                runSearch(setDialogState);
              }
            });
          }

          return AlertDialog(
            title: const Text('Search Images'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Search for an image',
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => runSearch(setDialogState),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: isLoading
                            ? null
                            : () => runSearch(setDialogState),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (errorMessage != null)
                    Text(errorMessage!, style: TextStyle(color: context.error)),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (results.isNotEmpty)
                    SizedBox(
                      height: 360,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];
                          final previewUrl =
                              result.thumbnailUrl ?? result.imageUrl;
                          return InkWell(
                            onTap: () async {
                              Navigator.of(dialogContext).pop();
                              await _saveImage(
                                operation: () =>
                                    widget.contentService.saveTermImageFromUrl(
                                      widget.termForm.languageId,
                                      widget.termForm.term,
                                      result.imageUrl,
                                    ),
                                successMessage: 'Image saved',
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Ink(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: context.appColorScheme.border.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  previewUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildImagePlaceholder(context),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveImage({
    required Future<TermImageUploadResult> Function() operation,
    required String successMessage,
  }) async {
    if (_isSavingImage) return;

    setState(() {
      _isSavingImage = true;
    });

    try {
      final result = await operation();
      setState(() {
        _currentImageUrl = result.imageUrl ?? _currentImageUrl;
        _currentImageFilename = result.imageFilename ?? _currentImageFilename;
      });
      _imageDialogSetState?.call(() {});

      final updatedForm = widget.termForm.copyWith(
        imageUrl: _currentImageUrl,
        imageFilename: _currentImageFilename,
      );

      widget.onUpdate(updatedForm);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (e) {
      if (mounted) {
        final message = _extractErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image update failed: $message')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingImage = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _currentImageUrl = null;
      _currentImageFilename = null;
    });
    _imageDialogSetState?.call(() {});

    widget.onUpdate(widget.termForm.copyWith(clearImage: true));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image removed')));
    }
  }

  String _extractErrorMessage(Object error) {
    final raw = error.toString();
    final marker = 'Exception: ';
    final normalized = raw.startsWith(marker)
        ? raw.substring(marker.length)
        : raw;

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map) {
        for (final key in const ['error', 'message', 'detail']) {
          final value = decoded[key]?.toString().trim();
          if (value != null && value.isNotEmpty) {
            return value;
          }
        }
      }
    } catch (_) {
      // Fall back to the raw error text.
    }

    return normalized;
  }

  Widget _buildTagsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tags',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.m3Secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddTagDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Tag'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (widget.termForm.tags != null && widget.termForm.tags!.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.termForm.tags!.map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTagChip(context, tag),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    return GestureDetector(
      onLongPress: () => _showDeleteTagConfirmation(context, tag),
      child: Chip(
        label: Text(tag),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: null,
      ),
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter tag name'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addTag(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addTag(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    if (widget.termForm.tags == null) {
      final updatedForm = widget.termForm.copyWith(tags: [tag]);
      widget.onUpdate(updatedForm);
    } else {
      if (!widget.termForm.tags!.contains(tag)) {
        final updatedForm = widget.termForm.copyWith(
          tags: [...widget.termForm.tags!, tag],
        );
        widget.onUpdate(updatedForm);
      }
    }
  }

  void _showDeleteTagConfirmation(BuildContext context, String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Tag'),
        content: Text('Remove tag "$tag"?'),
        actions: [
          TextButton(
            onPressed: () {
              _removeTag(tag);
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _removeTag(String tag) {
    if (widget.termForm.tags != null) {
      final updatedForm = widget.termForm.copyWith(
        tags: widget.termForm.tags!.where((t) => t != tag).toList(),
      );
      widget.onUpdate(updatedForm);
    }
  }

  Widget _buildParentsSection(BuildContext context) {
    final settings = ref.watch(termFormSettingsProvider);
    final isInDictionaryMode =
        _isDictionaryOpen && settings.showParentsInDictionary;

    if (isInDictionaryMode) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...widget.termForm.parents.map((parent) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildParentChip(context, parent),
              );
            }),
            ElevatedButton.icon(
              onPressed: () => _showAddParentDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Parent'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
          ],
        ),
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
                color: context.m3Secondary,
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
                          ? context.success
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.termForm.parents.map((parent) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildParentChip(context, parent),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildParentChip(BuildContext context, TermParent parent) {
    final status = parent.status?.toString() ?? '0';
    final textColor = context.getStatusTextColor(status);
    final backgroundColor = context.getStatusBackgroundColor(status);

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
        title: const Text('Remove Parent'),
        content: Text('Remove parent term from "${parent.term}"?'),
        actions: [
          TextButton(
            onPressed: () {
              _removeParent(parent);
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
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
      sentence: widget.sentence,
      dictionaries: _dictionaries,
      languageId: widget.termForm.languageId,
      onClose: _toggleDictionary,
      isVisible: _isDictionaryOpen,
      dictionaryService: _dictionaryService,
      onAddAITranslation: _handleAddAITranslationToField,
    );
  }

  void _handleAddAITranslationToField(String translation) {
    final currentText = _translationController.text.trim().replaceAll(
      '\n',
      ' ',
    );
    final cleanTranslation = translation.replaceAll('\n', ' ');
    final newText = currentText.isEmpty
        ? cleanTranslation
        : '$currentText, $cleanTranslation';

    _translationController.text = newText;
    _updateForm();
  }
}
