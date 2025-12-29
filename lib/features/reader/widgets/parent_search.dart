import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/term_form.dart';
import '../models/term_tooltip.dart';
import '../../../core/network/content_service.dart';
import '../../../shared/theme/theme_extensions.dart';

class ParentSearchWidget extends ConsumerStatefulWidget {
  final int languageId;
  final List<int> existingParentIds;
  final Function(TermParent) onParentSelected;
  final ContentService contentService;
  final Function() onDone;

  const ParentSearchWidget({
    super.key,
    required this.languageId,
    required this.existingParentIds,
    required this.onParentSelected,
    required this.contentService,
    required this.onDone,
  });

  @override
  ConsumerState<ParentSearchWidget> createState() => _ParentSearchWidgetState();
}

class _ParentSearchWidgetState extends ConsumerState<ParentSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResultTerm> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchTerms(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      final results = await widget.contentService.searchTerms(
        query,
        widget.languageId,
      );

      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = results
              .where(
                (result) =>
                    result.id != null &&
                    !widget.existingParentIds.contains(result.id),
              )
              .take(10)
              .toList();
        });
      }
    } catch (e) {
      print('Error searching terms: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _addCustomParent() async {
    final termText = _searchController.text.trim();
    if (termText.isEmpty) return;

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      await widget.contentService.createTerm(widget.languageId, termText);

      final results = await widget.contentService.searchTerms(
        termText,
        widget.languageId,
      );

      if (results.isNotEmpty && results.first.id != null) {
        final result = results.first;
        widget.onParentSelected(
          TermParent(
            id: result.id,
            term: result.text,
            translation: result.translation,
          ),
        );
        widget.onDone();
      } else {
        print('Error: Created term not found or has no ID');
      }
    } catch (e) {
      print('Error creating parent term: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
      _searchController.clear();
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Parent Term',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Search for a term or type new term name...',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _searchTerms,
        ),
        const SizedBox(height: 8),
        if (_searchController.text.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _addCustomParent,
            icon: const Icon(Icons.add),
            label: const Text('Add as New Parent Term'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _searchResults.map((result) {
                return InkWell(
                  onTap: () {
                    print(
                      'Term clicked: ${result.text}, status: ${result.status}',
                    );
                    widget.onParentSelected(
                      TermParent(
                        id: result.id,
                        term: result.text,
                        translation: result.translation,
                        status: result.status,
                      ),
                    );
                    widget.onDone();
                    _searchController.clear();
                    if (mounted) {
                      setState(() {
                        _searchResults = [];
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusHighlight(context, result),
                        if (result.translation != null)
                          Text(
                            '(${result.translation!})',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusHighlight(BuildContext context, SearchResultTerm result) {
    final status = result.status?.toString() ?? '0';
    final textColor = Theme.of(context).colorScheme.getStatusTextColor(status);
    final backgroundColor = Theme.of(
      context,
    ).colorScheme.getStatusBackgroundColor(status);

    if (backgroundColor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(result.text, style: TextStyle(color: textColor)),
      );
    }

    return Text(result.text, style: TextStyle(color: textColor));
  }
}
