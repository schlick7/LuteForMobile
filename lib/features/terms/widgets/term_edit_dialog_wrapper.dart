import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term.dart';
import '../../../shared/providers/language_data_provider.dart';
import '../../../shared/providers/network_providers.dart';
import '../../reader/widgets/term_form.dart';

class TermEditDialogWrapper extends ConsumerStatefulWidget {
  final Term term;
  final VoidCallback onDelete;

  const TermEditDialogWrapper({
    super.key,
    required this.term,
    required this.onDelete,
  });

  @override
  ConsumerState<TermEditDialogWrapper> createState() =>
      _TermEditDialogWrapperState();
}

class _TermEditDialogWrapperState extends ConsumerState<TermEditDialogWrapper> {
  TermForm? _termForm;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTermForm();
  }

  Future<void> _loadTermForm() async {
    try {
      final contentService = ref.read(contentServiceProvider);
      _termForm = await contentService.getTermFormById(widget.term.id);
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Term'),
        actions: [
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
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Term updated successfully')),
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
          onUpdate: (_) {},
          onCancel: () => Navigator.pop(context),
          contentService: ref.read(contentServiceProvider),
          dictionaryService: ref.read(dictionaryServiceProvider),
        ),
      ),
    );
  }
}
