import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_create.dart';
import '../providers/books_provider.dart';

class EditBookDialog extends ConsumerStatefulWidget {
  final int bookId;

  const EditBookDialog({super.key, required this.bookId});

  @override
  ConsumerState<EditBookDialog> createState() => _EditBookDialogState();
}

class _EditBookDialogState extends ConsumerState<EditBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _sourceUriController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _currentAudioFilename = '';
  String? _newAudioFilePath;
  String? _newAudioFileName;
  bool _removeCurrentAudio = false;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sourceUriController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadForm() async {
    try {
      final form = await ref
          .read(booksProvider.notifier)
          .getBookEditForm(widget.bookId);
      if (!mounted) return;
      setState(() {
        _titleController.text = form.title;
        _sourceUriController.text = form.sourceUri;
        _tagsController.text = form.tags.join(', ');
        _currentAudioFilename = form.audioFilename;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(e.toString());
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.pickFiles(
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
        _newAudioFilePath = file.path;
        _newAudioFileName = file.name;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final request = BookEditRequest(
      bookId: widget.bookId,
      title: _titleController.text.trim(),
      sourceUri: _sourceUriController.text.trim(),
      tags: tags,
      audioFilename: _removeCurrentAudio ? '' : _currentAudioFilename,
      audioFilePath: _newAudioFilePath,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(booksProvider.notifier).editBook(request);
      if (!mounted) return;
      Navigator.of(context).pop(true);
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Book'),
      content: SizedBox(
        width: 560,
        child: _isLoading
            ? const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      if (_currentAudioFilename.isNotEmpty) ...[
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _removeCurrentAudio,
                          title: const Text('Remove current audio'),
                          subtitle: Text(_currentAudioFilename),
                          onChanged: (value) {
                            setState(() {
                              _removeCurrentAudio = value ?? false;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _newAudioFileName == null
                                  ? 'New audio file: none selected'
                                  : 'New audio file: $_newAudioFileName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _pickAudioFile,
                            child: const Text('Pick Audio File'),
                          ),
                          if (_newAudioFilePath != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                setState(() {
                                  _newAudioFilePath = null;
                                  _newAudioFileName = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
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
