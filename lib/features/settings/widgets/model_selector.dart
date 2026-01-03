import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/providers/ai_provider.dart';

class ModelSelector extends ConsumerStatefulWidget {
  final String? selectedModel;
  final ValueChanged<String> onModelSelected;
  final String labelText;
  final String? hintText;

  const ModelSelector({
    super.key,
    required this.selectedModel,
    required this.onModelSelected,
    this.labelText = 'Model',
    this.hintText,
  });

  @override
  ConsumerState<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends ConsumerState<ModelSelector> {
  bool _isFetching = false;
  List<String> _models = [];
  String? _error;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: widget.selectedModel,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText ?? 'Select or enter model',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: _isFetching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: _fetchModels,
          tooltip: 'Fetch available models',
        ),
      ),
      items: _models.map((model) {
        return DropdownMenuItem(value: model, child: Text(model));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          widget.onModelSelected(value);
        }
      },
    );
  }

  Future<void> _fetchModels() async {
    setState(() {
      _isFetching = true;
      _error = null;
    });

    try {
      final models = await ref.read(aiModelsProvider.future);
      setState(() {
        _models = models;
        _isFetching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isFetching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch models: $_error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
