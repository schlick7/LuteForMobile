import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/language.dart';
import '../models/book_create.dart';
import '../providers/books_provider.dart';
import '../../../shared/providers/network_providers.dart';

class AddBookDialog extends ConsumerStatefulWidget {
  const AddBookDialog({super.key});

  @override
  ConsumerState<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends ConsumerState<AddBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final _sourceUriController = TextEditingController();
  final _tagsController = TextEditingController();
  final _importUrlController = TextEditingController();
  final _thresholdController = TextEditingController(text: '250');

  List<Language> _languages = const [];
  int? _selectedLanguageId;
  String _splitBy = 'paragraphs';
  bool _isLoadingLanguages = true;
  bool _isSaving = false;
  bool _isImporting = false;
  String? _textFilePath;
  String? _textFileName;
  String? _audioFilePath;
  String? _audioFileName;

  @override
  void initState() {
    super.initState();
    _loadLanguages();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _sourceUriController.dispose();
    _tagsController.dispose();
    _importUrlController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadLanguages() async {
    try {
      final contentService = ref.read(contentServiceProvider);
      final languages = await contentService.getLanguagesWithIds();
      int? currentLanguageId;
      final currentLanguageSetting = await contentService.getUserSetting(
        'current_language_id',
      );
      if (currentLanguageSetting != null) {
        currentLanguageId = int.tryParse(currentLanguageSetting);
      }

      if (!mounted) return;
      setState(() {
        _languages = languages;
        _selectedLanguageId =
            currentLanguageId ??
            (languages.isNotEmpty ? languages.first.id : null);
        _isLoadingLanguages = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLanguages = false;
      });
    }
  }

  Future<void> _importFromUrl() async {
    final url = _importUrlController.text.trim();
    if (url.isEmpty) {
      _showError('Enter a URL to import.');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final preview = await ref
          .read(booksProvider.notifier)
          .previewBookImportFromUrl(url);
      if (!mounted) return;
      setState(() {
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = preview.title;
        }
        _sourceUriController.text = preview.sourceUri;
        _textController.text = preview.text;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<void> _pickTextFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'epub', 'pdf', 'srt', 'vtt'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.path == null || file.path!.isEmpty) {
        _showError('Could not access selected file path.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _textFilePath = file.path;
        _textFileName = file.name;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = _filenameWithoutExtension(file.name);
        }
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'mp3',
          'm4a',
          'wav',
          'ogg',
          'opus',
          'aac',
          'flac',
          'webm',
        ],
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      if (file.path == null || file.path!.isEmpty) {
        _showError('Could not access selected file path.');
        return;
      }

      if (!mounted) return;
      setState(() {
        _audioFilePath = file.path;
        _audioFileName = file.name;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final languageId = _selectedLanguageId;
    if (languageId == null || languageId <= 0) {
      _showError('Please select a language.');
      return;
    }

    final threshold = int.tryParse(_thresholdController.text.trim());
    if (threshold == null || threshold < 1 || threshold > 1500) {
      _showError('Words per page must be between 1 and 1500.');
      return;
    }

    final hasText = _textController.text.trim().isNotEmpty;
    final hasTextFile = _textFilePath != null && _textFilePath!.isNotEmpty;

    if (hasText && hasTextFile) {
      _showError('Both Text and Text file are set, please only specify one.');
      return;
    }

    if (!hasText && !hasTextFile) {
      _showError('Please specify either Text or Text file.');
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final request = BookCreateRequest(
      languageId: languageId,
      title: _titleController.text.trim(),
      text: _textController.text.trim(),
      sourceUri: _sourceUriController.text.trim(),
      tags: tags,
      splitBy: _splitBy,
      thresholdPageTokens: threshold,
      textFilePath: _textFilePath,
      audioFilePath: _audioFilePath,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final newBookId = await ref
          .read(booksProvider.notifier)
          .createBook(request);
      if (!mounted) return;
      Navigator.of(context).pop(newBookId);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _filenameWithoutExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot <= 0) return filename;
    return filename.substring(0, dot);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Book'),
      content: SizedBox(
        width: 560,
        child: _isLoadingLanguages
            ? const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _importUrlController,
                        decoration: InputDecoration(
                          labelText: 'Import URL',
                          hintText: 'https://example.com/article',
                          suffixIcon: _isImporting
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download),
                                  tooltip: 'Import',
                                  onPressed: _importFromUrl,
                                ),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedLanguageId,
                        decoration: const InputDecoration(
                          labelText: 'Language',
                        ),
                        items: _languages
                            .map(
                              (lang) => DropdownMenuItem<int>(
                                value: lang.id,
                                child: Text(lang.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLanguageId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          labelText: 'Text',
                          alignLabelWithHint: true,
                        ),
                        minLines: 6,
                        maxLines: 12,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _textFileName == null
                                  ? 'Text file: none selected'
                                  : 'Text file: $_textFileName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _pickTextFile,
                            child: const Text('Pick Text File'),
                          ),
                          if (_textFilePath != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                setState(() {
                                  _textFilePath = null;
                                  _textFileName = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _audioFileName == null
                                  ? 'Audio file: none selected'
                                  : 'Audio file: $_audioFileName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _pickAudioFile,
                            child: const Text('Pick Audio File'),
                          ),
                          if (_audioFilePath != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                setState(() {
                                  _audioFilePath = null;
                                  _audioFileName = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sourceUriController,
                        decoration: const InputDecoration(
                          labelText: 'Text source',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags',
                          hintText: 'tag1, tag2',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _splitBy,
                        decoration: const InputDecoration(
                          labelText: 'Split by',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'paragraphs',
                            child: Text('Paragraphs'),
                          ),
                          DropdownMenuItem(
                            value: 'sentences',
                            child: Text('Sentences'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _splitBy = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _thresholdController,
                        decoration: const InputDecoration(
                          labelText: 'Words per page',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
