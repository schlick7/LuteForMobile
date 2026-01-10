import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term.dart';
import '../../../shared/providers/network_providers.dart';
import '../../reader/models/term_form.dart';
import '../../reader/widgets/term_form.dart' show TermFormWidget;

class TermEditDialogWrapper extends ConsumerStatefulWidget {
  final Term term;
  final VoidCallback onDelete;
  final VoidCallback? onSave;

  const TermEditDialogWrapper({
    super.key,
    required this.term,
    required this.onDelete,
    this.onSave,
  });

  @override
  ConsumerState<TermEditDialogWrapper> createState() =>
      _TermEditDialogWrapperState();
}

class _TermEditDialogWrapperState extends ConsumerState<TermEditDialogWrapper> {
  TermForm? _termForm;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadTermForm();
  }

  Future<void> _loadTermForm() async {
    try {
      final contentService = ref.read(contentServiceProvider);
      _termForm = await contentService.getTermFormByIdWithParentDetails(
        widget.term.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load term: $e')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _termForm == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).appBarTheme.backgroundColor,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Edit Term',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Term'),
                      content: const Text(
                        'Are you sure you want to delete this term?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDelete();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: TermFormWidget(
              termForm: _termForm!,
              onSave: (updatedForm) async {
                try {
                  final contentService = ref.read(contentServiceProvider);
                  await contentService.editTerm(
                    updatedForm.termId!,
                    updatedForm.toFormData(),
                  );
                  if (mounted) {
                    widget.onSave?.call();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Term updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update term: $e')),
                    );
                  }
                }
              },
              onUpdate: (updatedForm) async {
                setState(() {
                  _termForm = updatedForm;
                });
                try {
                  setState(() {
                    _isSaving = true;
                  });
                  final contentService = ref.read(contentServiceProvider);
                  await contentService.editTerm(
                    updatedForm.termId!,
                    updatedForm.toFormData(),
                  );
                  if (mounted) {
                    widget.onSave?.call();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Term updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update term: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                    });
                  }
                }
              },
              onCancel: () => Navigator.pop(context),
              contentService: ref.read(contentServiceProvider),
              dictionaryService: ref.read(dictionaryServiceProvider),
            ),
          ),
        ),
      ],
    );
  }
}
