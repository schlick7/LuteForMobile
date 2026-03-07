import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/language.dart';
import '../../../shared/models/language_card_settings.dart';
import '../../../shared/providers/network_providers.dart';
import '../../../shared/theme/theme_extensions.dart';

class LanguageSettingsCard extends ConsumerStatefulWidget {
  const LanguageSettingsCard({super.key});

  @override
  ConsumerState<LanguageSettingsCard> createState() =>
      _LanguageSettingsCardState();
}

class _LanguageSettingsCardState extends ConsumerState<LanguageSettingsCard> {
  final _nameController = TextEditingController();
  final _characterSubstitutionsController = TextEditingController();
  final _regexpSplitSentencesController = TextEditingController();
  final _exceptionsSplitSentencesController = TextEditingController();
  final _wordCharactersController = TextEditingController();

  List<Language> _languages = const [];
  List<String> _predefinedLanguageNames = const [];
  int? _selectedLanguageId;
  String? _selectedPredefinedLanguage;
  LanguageCardSettings? _settings;

  bool _isLoadingLanguages = false;
  bool _isLoadingPredefined = false;
  bool _isLoadingSettings = false;
  bool _isSaving = false;
  bool _isQuickLoadingPredefined = false;
  bool _isCreateMode = false;
  String? _createTemplateName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _characterSubstitutionsController.dispose();
    _regexpSplitSentencesController.dispose();
    _exceptionsSplitSentencesController.dispose();
    _wordCharactersController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadLanguages(), _loadPredefinedLanguageNames()]);
  }

  Future<void> _loadLanguages() async {
    setState(() {
      _isLoadingLanguages = true;
      _error = null;
    });

    try {
      final contentService = ref.read(contentServiceProvider);
      final languages = await contentService.getLanguagesWithIds();

      if (!mounted) return;
      setState(() {
        _languages = languages;
        if (!_isCreateMode) {
          _selectedLanguageId = languages.isNotEmpty
              ? languages.first.id
              : null;
        }
      });

      if (!_isCreateMode && _selectedLanguageId != null) {
        await _loadLanguageSettings(_selectedLanguageId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load languages: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLanguages = false;
        });
      }
    }
  }

  Future<void> _loadPredefinedLanguageNames() async {
    setState(() {
      _isLoadingPredefined = true;
      _error = null;
    });

    try {
      final contentService = ref.read(contentServiceProvider);
      final names = await contentService.getPredefinedLanguageNames();
      if (!mounted) return;
      setState(() {
        _predefinedLanguageNames = names;
        _selectedPredefinedLanguage = names.isNotEmpty ? names.first : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load predefined languages: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPredefined = false;
        });
      }
    }
  }

  Future<void> _loadLanguageSettings(int languageId) async {
    setState(() {
      _isLoadingSettings = true;
      _error = null;
      _isCreateMode = false;
      _createTemplateName = null;
    });

    try {
      final contentService = ref.read(contentServiceProvider);
      final settings = await contentService.getLanguageCardSettings(languageId);
      _applyLoadedSettings(settings);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load language settings: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  Future<void> _startCreateLanguage({String? templateName}) async {
    setState(() {
      _isLoadingSettings = true;
      _error = null;
      _isCreateMode = true;
      _createTemplateName = templateName;
    });

    try {
      final contentService = ref.read(contentServiceProvider);
      final settings = await contentService.getNewLanguageCardSettings(
        templateName: templateName,
      );
      _applyLoadedSettings(settings);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load create-language form: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  void _applyLoadedSettings(LanguageCardSettings settings) {
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _nameController.text = settings.name;
      _characterSubstitutionsController.text = settings.characterSubstitutions;
      _regexpSplitSentencesController.text = settings.regexpSplitSentences;
      _exceptionsSplitSentencesController.text =
          settings.exceptionsSplitSentences;
      _wordCharactersController.text = settings.wordCharacters;
    });
  }

  Future<void> _saveLanguageSettings() async {
    final settings = _settings;
    if (settings == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final contentService = ref.read(contentServiceProvider);
      final payload = settings.copyWith(
        name: _nameController.text.trim(),
        characterSubstitutions: _characterSubstitutionsController.text.trim(),
        regexpSplitSentences: _regexpSplitSentencesController.text.trim(),
        exceptionsSplitSentences: _exceptionsSplitSentencesController.text
            .trim(),
        wordCharacters: _wordCharactersController.text.trim(),
      );

      if (_isCreateMode) {
        await contentService.createLanguageCardSettings(
          payload,
          templateName: _createTemplateName,
        );
      } else {
        await contentService.saveLanguageCardSettings(payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCreateMode
                ? 'Language created successfully'
                : 'Language settings saved',
          ),
        ),
      );
      await _refreshLanguagesAndSelect(languageName: payload.name);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save language settings: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _quickLoadPredefinedLanguage() async {
    final selected = _selectedPredefinedLanguage;
    if (selected == null || selected.isEmpty) return;

    setState(() {
      _isQuickLoadingPredefined = true;
      _error = null;
    });

    try {
      final contentService = ref.read(contentServiceProvider);
      await contentService.loadPredefinedLanguage(selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded predefined language: $selected')),
      );
      await _refreshLanguagesAndSelect(languageName: selected);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load predefined language: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isQuickLoadingPredefined = false;
        });
      }
    }
  }

  Future<void> _deleteSelectedLanguage() async {
    final languageId = _selectedLanguageId;
    if (_isCreateMode || languageId == null) return;

    final languageName = _languages
        .where((lang) => lang.id == languageId)
        .map((lang) => lang.name)
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => 'this language');

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete language?'),
          content: Text(
            'Deleting $languageName will also delete its books and terms. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final contentService = ref.read(contentServiceProvider);
      await contentService.deleteLanguage(languageId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Language deleted')));
      await _refreshLanguagesAndSelect();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to delete language: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _refreshLanguagesAndSelect({String? languageName}) async {
    final contentService = ref.read(contentServiceProvider);
    final languages = await contentService.getLanguagesWithIds();
    if (!mounted) return;

    int? selectedId;
    if (languageName != null && languageName.isNotEmpty) {
      for (final language in languages) {
        if (language.name.toLowerCase() == languageName.toLowerCase()) {
          selectedId = language.id;
          break;
        }
      }
    }
    selectedId ??= languages.isNotEmpty ? languages.first.id : null;

    setState(() {
      _languages = languages;
      _selectedLanguageId = selectedId;
      _isCreateMode = false;
      _createTemplateName = null;
    });

    if (selectedId != null) {
      await _loadLanguageSettings(selectedId);
    } else {
      setState(() {
        _settings = null;
      });
    }
  }

  void _updateSettings(LanguageCardSettings Function(LanguageCardSettings) fn) {
    setState(() {
      final settings = _settings;
      if (settings == null) return;
      _settings = fn(settings);
    });
  }

  void _updateDictionary(
    int index,
    LanguageDictionarySetting Function(LanguageDictionarySetting) fn,
  ) {
    _updateSettings((settings) {
      final dictionaries = [...settings.dictionaries];
      dictionaries[index] = fn(dictionaries[index]);
      return settings.copyWith(dictionaries: dictionaries);
    });
  }

  void _removeDictionary(int index) {
    _updateSettings((settings) {
      final dictionaries = [...settings.dictionaries]..removeAt(index);
      return settings.copyWith(dictionaries: dictionaries);
    });
  }

  void _addDictionary() {
    _updateSettings((settings) {
      final dictionaries = [...settings.dictionaries];
      dictionaries.add(
        LanguageDictionarySetting(
          useFor: 'terms',
          dictType: 'embeddedhtml',
          dictUri: '',
          isActive: true,
          sortOrder: dictionaries.length + 1,
        ),
      );
      return settings.copyWith(dictionaries: dictionaries);
    });
  }

  Future<void> _showNewLanguageDialog() async {
    String? selected = _selectedPredefinedLanguage;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingPredefined)
                    const Center(child: CircularProgressIndicator())
                  else if (_predefinedLanguageNames.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: selected,
                      decoration: const InputDecoration(
                        labelText: 'Predefined Language',
                        border: OutlineInputBorder(),
                      ),
                      items: _predefinedLanguageNames
                          .map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selected = value;
                        });
                      },
                    )
                  else
                    const Text('No predefined languages found on server.'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startCreateLanguage();
                        },
                        child: const Text('Custom New'),
                      ),
                      ElevatedButton(
                        onPressed: selected == null
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                _startCreateLanguage(templateName: selected);
                              },
                        child: const Text('Prefill Template'),
                      ),
                      ElevatedButton(
                        onPressed: selected == null || _isQuickLoadingPredefined
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                setState(() {
                                  _selectedPredefinedLanguage = selected;
                                });
                                await _quickLoadPredefinedLanguage();
                              },
                        child: const Text('Quick Load Predefined'),
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final parserOptions = settings == null
        ? const <String>[]
        : {
            ...settings.parserTypeOptions,
            if (settings.parserType.isNotEmpty) settings.parserType,
          }.toList();

    return Card(
      elevation: 2,
      child: ExpansionTile(
        initiallyExpanded: false,
        title: const Text(
          'Language Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _showNewLanguageDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Language'),
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: TextStyle(color: context.appColorScheme.error.error),
              ),
            ),
          const Divider(height: 16),
          _buildEditorSection(context, settings, parserOptions),
        ],
      ),
    );
  }

  Widget _buildEditorSection(
    BuildContext context,
    LanguageCardSettings? settings,
    List<String> parserOptions,
  ) {
    if (_isLoadingLanguages || _isLoadingSettings) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_languages.isEmpty && !_isCreateMode) {
      return const Text('No languages available on the server');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_languages.isNotEmpty)
          DropdownButtonFormField<int>(
            initialValue: _selectedLanguageId,
            decoration: InputDecoration(
              labelText: _isCreateMode ? 'Edit Existing Language' : 'Language',
              border: const OutlineInputBorder(),
            ),
            items: _languages
                .map(
                  (language) => DropdownMenuItem<int>(
                    value: language.id,
                    child: Text(language.name),
                  ),
                )
                .toList(),
            onChanged: (value) async {
              if (value == null || value == _selectedLanguageId) return;
              setState(() {
                _selectedLanguageId = value;
              });
              await _loadLanguageSettings(value);
            },
          ),
        if (_isCreateMode) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _createTemplateName == null
                      ? 'Create mode: /language/new'
                      : 'Create mode: /language/new/${_createTemplateName!}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: _selectedLanguageId == null
                    ? null
                    : () => _loadLanguageSettings(_selectedLanguageId!),
                child: const Text('Cancel Create'),
              ),
            ],
          ),
        ],
        if (settings != null) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Pronunciation'),
                  value: settings.showRomanization,
                  onChanged: (value) {
                    _updateSettings(
                      (current) => current.copyWith(showRomanization: value),
                    );
                  },
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Right-to-left'),
                  value: settings.rightToLeft,
                  onChanged: (value) {
                    _updateSettings(
                      (current) => current.copyWith(rightToLeft: value),
                    );
                  },
                ),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: settings.parserType,
            decoration: const InputDecoration(
              labelText: 'Parser Type',
              border: OutlineInputBorder(),
            ),
            items: parserOptions
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              _updateSettings((current) => current.copyWith(parserType: value));
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _characterSubstitutionsController,
            decoration: const InputDecoration(
              labelText: 'Character substitutions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regexpSplitSentencesController,
            decoration: const InputDecoration(
              labelText: 'Split sentences at',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _exceptionsSplitSentencesController,
            decoration: const InputDecoration(
              labelText: 'Split sentence exceptions',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _wordCharactersController,
            decoration: const InputDecoration(
              labelText: 'Word characters',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dictionaries',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _addDictionary,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          ...List.generate(settings.dictionaries.length, (index) {
            final dict = settings.dictionaries[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: dict.useFor,
                          decoration: const InputDecoration(
                            labelText: 'Use for',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'terms',
                              child: Text('Terms'),
                            ),
                            DropdownMenuItem(
                              value: 'sentences',
                              child: Text('Sentences'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            _updateDictionary(
                              index,
                              (current) => current.copyWith(useFor: value),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: dict.dictType,
                          decoration: const InputDecoration(
                            labelText: 'Show as',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'embeddedhtml',
                              child: Text('Embedded'),
                            ),
                            DropdownMenuItem(
                              value: 'popuphtml',
                              child: Text('Pop-up window'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            _updateDictionary(
                              index,
                              (current) => current.copyWith(dictType: value),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: dict.dictUri,
                    key: ValueKey(
                      'dict_${_isCreateMode ? 'new' : settings.languageId}_$index',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Dictionary URL',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateDictionary(
                        index,
                        (current) => current.copyWith(dictUri: value),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: dict.isActive,
                          title: const Text('Active'),
                          onChanged: (value) {
                            if (value == null) return;
                            _updateDictionary(
                              index,
                              (current) => current.copyWith(isActive: value),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeDictionary(index),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove dictionary',
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveLanguageSettings,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _isCreateMode
                              ? 'Create Language'
                              : 'Save Language Settings',
                        ),
                ),
              ),
              if (!_isCreateMode) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _isSaving ? null : _deleteSelectedLanguage,
                  child: const Text('Delete'),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
