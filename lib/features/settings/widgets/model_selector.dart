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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(aiModelsProvider);
    final isFetching = modelsAsync.isLoading;

    return DropdownButtonFormField<String>(
      value: modelsAsync.maybeWhen(
        data: (models) =>
            models.contains(widget.selectedModel) ? widget.selectedModel : null,
        orElse: () => null,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText ?? 'Select or enter model',
        border: const OutlineInputBorder(),
        errorText: modelsAsync.error != null ? 'Failed to load models' : null,
        suffixIcon: IconButton(
          icon: isFetching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: () {
            ref.read(aiModelsProvider.notifier).fetchModels();
          },
          tooltip: 'Fetch available models',
        ),
      ),
      items: modelsAsync.when(
        data: (models) {
          return models.map((model) {
            return DropdownMenuItem(value: model, child: Text(model));
          }).toList();
        },
        loading: () => [],
        error: (_, __) => [],
      ),
      onChanged: (value) {
        if (value != null) {
          widget.onModelSelected(value);
        }
      },
    );
  }
}
