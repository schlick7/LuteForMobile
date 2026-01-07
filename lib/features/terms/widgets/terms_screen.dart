import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_display.dart';
import '../providers/terms_provider.dart';
import '../models/term.dart';
import 'term_card.dart';
import 'term_filter_panel.dart';
import 'term_edit_dialog_wrapper.dart';

class TermsScreen extends ConsumerStatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const TermsScreen({super.key, this.scaffoldKey});

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(termsProvider.notifier).loadTerms(reset: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(termsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(termsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (widget.scaffoldKey != null &&
                  widget.scaffoldKey!.currentState != null) {
                widget.scaffoldKey!.currentState!.openDrawer();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
          ),
        ),
        title: const Text('Terms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterPanel(context),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildTermsList(state)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search terms...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(termsProvider.notifier).setSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
        onChanged: (value) {
          ref.read(termsProvider.notifier).setSearchQuery(value);
        },
      ),
    );
  }

  Widget _buildTermsList(TermsState state) {
    if (state.isLoading && state.terms.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (state.errorMessage != null) {
      return ErrorDisplay(
        message: state.errorMessage!,
        onRetry: () => ref.read(termsProvider.notifier).refreshTerms(),
      );
    }

    if (state.terms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.spellcheck, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No terms found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (state.selectedLangId == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Showing terms from all languages'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(termsProvider.notifier).refreshTerms(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.terms.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < state.terms.length) {
            return TermCard(
              term: state.terms[index],
              onTap: () => _showTermEditDialog(state.terms[index]),
            );
          } else if (state.hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return null;
        },
      ),
    );
  }

  void _showFilterPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TermFilterPanel(),
    );
  }

  void _showTermEditDialog(Term term) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TermEditDialogWrapper(
        term: term,
        onDelete: () async {
          await ref.read(termsProvider.notifier).deleteTerm(term.id);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}
