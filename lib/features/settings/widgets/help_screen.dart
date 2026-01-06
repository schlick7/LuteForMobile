import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Help'),
        elevation: 2,
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _buildReaderScreenSection(context),
              const SizedBox(height: 8),
              _buildTermFormSection(context),
              const SizedBox(height: 8),
              _buildSentenceReaderSection(context),
              const SizedBox(height: 8),
              _buildAudioPlayerSection(context),
              const SizedBox(height: 8),
              _buildSentenceTranslationSection(context),
              const SizedBox(height: 8),
              _buildBooksScreenSection(context),
              const SizedBox(height: 8),
              _buildAIFeaturesSection(context),
              const SizedBox(height: 16),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderScreenSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Reader Screen', Icons.menu_book),
          const Divider(),
          _buildSubsectionHeader(context, 'Main Controls'),
          _buildControlItem(context, Icons.menu, 'Menu icon', 'Opens drawer'),
          _buildControlItem(
            context,
            Icons.arrow_back,
            'Previous/Next page',
            'Navigate pages',
          ),
          _buildControlItem(
            context,
            Icons.check_circle,
            '"All Known" button',
            'Mark page as all known',
          ),
          _buildControlItem(
            context,
            Icons.format_list_numbered,
            'Page indicator',
            'Shows current page (e.g., "5/25")',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Text Interactions'),
          _buildControlItem(
            context,
            Icons.touch_app,
            'Tap word',
            'Show term tooltip',
          ),
          _buildControlItem(
            context,
            Icons.fingerprint,
            'Double-tap word',
            'Open term form',
          ),
          _buildControlItem(
            context,
            Icons.read_more,
            'Long-press word',
            'Show sentence translation',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Gestures'),
          _buildControlItem(
            context,
            Icons.swipe,
            'Swipe left/right',
            'Navigate pages',
          ),
          _buildControlItem(
            context,
            Icons.fullscreen,
            'Tap (fullscreen)',
            'Show/hide UI',
          ),
          _buildControlItem(
            context,
            Icons.arrow_upward,
            'Scroll to top',
            'Show UI',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Drawer Settings'),
          _buildControlItem(
            context,
            Icons.format_size,
            'Text formatting',
            'Text size, line spacing, font, weight, italic',
          ),
          _buildControlItem(
            context,
            Icons.fullscreen,
            'Fullscreen mode',
            'Toggle fullscreen mode',
          ),
          _buildControlItem(
            context,
            Icons.headphones,
            'Audio player',
            'Toggle audio player',
          ),
        ],
      ),
    );
  }

  Widget _buildTermFormSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Term Form Modal', Icons.edit_note),
          const Divider(),
          _buildSubsectionHeader(context, 'Fields'),
          _buildControlItem(
            context,
            Icons.translate,
            'Translation field',
            'Enter word translation',
          ),
          _buildControlItem(
            context,
            Icons.psychology,
            'Psychology icon',
            'Get AI translation',
          ),
          _buildControlItem(
            context,
            Icons.list,
            'Status Boxes',
            'Select learning status (1-5, Known, Ignored)',
          ),
          _buildControlItem(
            context,
            Icons.abc,
            'Romanization field',
            'Add romanization (for non-Latin scripts) Toggle in Settings',
          ),
          _buildControlItem(
            context,
            Icons.local_offer,
            'Tags field',
            'Add comma-separated tags. Toggle in Settings',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Controls'),
          _buildControlItem(
            context,
            Icons.book,
            'Dictionary section',
            'Toggleable dictionary view',
          ),
          _buildControlItem(context, Icons.save, 'Save button', 'Save changes'),
          _buildControlItem(
            context,
            Icons.close,
            'Cancel button',
            'Discard changes',
          ),
          _buildControlItem(
            context,
            Icons.swipe_down,
            'Swipe down',
            'Close (quick action) Toggle in Settings to Auto Save or Cancel',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Dictionary Features'),
          _buildControlItem(
            context,
            Icons.fingerprint,
            'Double-tap parent term',
            'Open parent\'s term form',
          ),
          _buildControlItem(
            context,
            Icons.link,
            'Parent Status Linked',
            'Toggle Parent status syncing. ',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'AI Features'),
          _buildControlItem(
            context,
            Icons.psychology,
            'Psychology icon',
            'Fetch AI translation',
          ),
          _buildControlItem(
            context,
            Icons.add_circle_outline,
            'Add To',
            'Adds to existing translations',
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceReaderSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Sentence Reader Screen', Icons.article),
          const Divider(),
          _buildSubsectionHeader(context, 'Navigation'),
          _buildControlItem(
            context,
            Icons.close,
            'Close button (Top Right)',
            'Return to Reader',
          ),
          _buildControlItem(
            context,
            Icons.arrow_back,
            'Previous/Next sentence arrows',
            'Navigate sentences',
          ),
          _buildControlItem(
            context,
            Icons.format_list_numbered,
            'Sentence position indicator',
            'Shows current sentence (e.g., "Sentence 5/25")',
          ),
          _buildControlItem(
            context,
            Icons.volume_up,
            'TTS button',
            'Play sentence audio',
          ),
          _buildControlItem(
            context,
            Icons.psychology,
            'Show Sentence Translation (Psychology icon)',
            'Open AI translation widget',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Text Interactions'),
          _buildControlItem(
            context,
            Icons.touch_app,
            'Tap word',
            'Show term tooltip',
          ),
          _buildControlItem(
            context,
            Icons.fingerprint,
            'Double-tap word',
            'Edit term (open term form)',
          ),
          _buildControlItem(
            context,
            Icons.read_more,
            'Long-press word',
            'Show sentence translation',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Bottom Section (Terms List)'),
          _buildControlItem(
            context,
            Icons.list,
            'Term list',
            'List with translation for each term',
          ),
          _buildControlItem(
            context,
            Icons.fingerprint,
            'Double-tap term',
            'Edit term',
          ),
          _buildControlItem(
            context,
            Icons.toggle_on,
            'Known Toggle (in Hamburger Settings)',
            'Toggles showing known terms in the list',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Drawer Settings'),
          _buildControlItem(
            context,
            Icons.article,
            '"Open Sentence Reader" button',
            'Switch to sentence reader mode',
          ),
          _buildControlItem(
            context,
            Icons.visibility,
            '"Show Known Terms" toggle',
            'Include status 99 (Known) terms in Termslist',
          ),
          _buildControlItem(
            context,
            Icons.refresh,
            '"Flush Cache & Rebuild" button',
            'Clear sentence cache and reload',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'AI Translation Widget'),
          _buildControlItem(
            context,
            Icons.text_fields,
            'Original sentence',
            'Display original sentence',
          ),
          _buildControlItem(
            context,
            Icons.translate,
            'AI translation',
            'Display AI translation',
          ),
          _buildControlItem(
            context,
            Icons.close,
            'Close button',
            'Dismiss widget',
          ),
          _buildControlItem(
            context,
            Icons.refresh,
            'Retry button',
            'Retry failed translation',
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayerSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Audio Player', Icons.headphones),
          const Divider(),
          _buildSubsectionHeader(context, 'Playback Controls'),
          _buildControlItem(
            context,
            Icons.play_arrow,
            'Play/Pause button',
            'Toggle playback',
          ),
          _buildControlItem(
            context,
            Icons.linear_scale,
            'Progress slider',
            'Seek to position (draggable)',
          ),
          _buildControlItem(
            context,
            Icons.bookmark,
            'Bookmark indicators',
            'Yellow markers on progress bar',
          ),
          _buildControlItem(
            context,
            Icons.skip_previous,
            'Previous bookmark button',
            'Jump to earlier bookmark',
          ),
          _buildControlItem(
            context,
            Icons.skip_next,
            'Next bookmark button',
            'Jump to next bookmark',
          ),
          _buildControlItem(
            context,
            Icons.bookmark_add,
            'Add/Remove bookmark button',
            'Toggle bookmark at current position',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Navigation Controls'),
          _buildControlItem(
            context,
            Icons.replay_10,
            'Rewind 10s button',
            'Skip back 10 seconds',
          ),
          _buildControlItem(
            context,
            Icons.forward_10,
            'Forward 10s button',
            'Skip forward 10 seconds',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Speed Control'),
          _buildControlItem(
            context,
            Icons.speed,
            'Playback speed button',
            'Cycle through speeds (0.6x, 0.7x, 0.8x, 0.9x, 1.0x, 1.1x, 1.2x, 1.3x, 1.4x, 1.5x)',
          ),
          _buildControlItem(
            context,
            Icons.timer,
            'Position display',
            'Current position / Total duration (e.g., "1:23 / 5:45")',
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceTranslationSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Sentence Translation Modal',
            Icons.translate,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Open by long-pressing term',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Controls'),
          _buildControlItem(
            context,
            Icons.library_books,
            'Dictionary selector',
            'Swipe or tap to change dictionary source',
          ),
          _buildControlItem(
            context,
            Icons.article,
            'Translation display',
            'Shows translated sentence text',
          ),
          _buildControlItem(
            context,
            Icons.volume_up,
            'TTS button',
            'Play sentence audio',
          ),
          _buildSubsectionHeader(context, 'Features'),
          _buildControlItem(
            context,
            Icons.list,
            'Multiple dictionary sources',
            'Configured in Lute Server language settings',
          ),
          _buildControlItem(
            context,
            Icons.history,
            'Automatic selection',
            'Based on last used dictionary',
          ),
          _buildControlItem(
            context,
            Icons.web,
            'Inline web view',
            'Rich dictionary content',
          ),
        ],
      ),
    );
  }

  Widget _buildBooksScreenSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Books Screen',
            Icons.collections_bookmark,
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Search & Filter'),
          _buildControlItem(
            context,
            Icons.search,
            'Search field',
            'Type to filter books (auto-updates)',
          ),
          _buildControlItem(
            context,
            Icons.clear,
            'Clear button',
            'Remove search text',
          ),
          _buildControlItem(
            context,
            Icons.filter_list,
            '"Active Only" / "Show Archived" chip',
            'Toggle archived books display',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Book Cards'),
          _buildControlItem(
            context,
            Icons.touch_app,
            'Tap card',
            'Open in Reader (loads current page)',
          ),
          _buildControlItem(
            context,
            Icons.read_more,
            'Long-press card',
            'Show details dialog (archived, audio, etc.)',
          ),
          _buildControlItem(
            context,
            Icons.check_circle,
            'Checkmark icon',
            'Book completed',
          ),
          _buildControlItem(
            context,
            Icons.headphones,
            'Audio icon',
            'Book has audio',
          ),
          _buildControlItem(
            context,
            Icons.linear_scale,
            'Status distribution bar',
            'Visual breakdown of term status',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Card Information'),
          _buildControlItem(context, Icons.title, 'Title', 'Book title'),
          _buildControlItem(
            context,
            Icons.language,
            'Language',
            'Book language',
          ),
          _buildControlItem(
            context,
            Icons.text_fields,
            'Word count',
            'Total word count',
          ),
          _buildControlItem(
            context,
            Icons.format_list_numbered,
            'Distinct terms count',
            'Number of unique terms',
          ),
          _buildControlItem(
            context,
            Icons.format_list_numbered,
            'Page progress',
            'Current page and total (e.g., "5/25")',
          ),
          _buildControlItem(
            context,
            Icons.local_offer,
            'Tags',
            'Book tags (if shown)',
          ),
          _buildControlItem(
            context,
            Icons.access_time,
            'Last read time',
            'Time since last read (if shown)',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Book Details Dialog'),
          _buildControlItem(
            context,
            Icons.archive,
            'Toggle archived status',
            'Archive or unarchive book',
          ),
          _buildControlItem(
            context,
            Icons.edit,
            'Edit book',
            'Edit book information',
          ),
          _buildControlItem(
            context,
            Icons.menu_book,
            'Navigate to book',
            'Open book in reader',
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeaturesSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'AI Features', Icons.psychology),
          const Divider(),
          _buildSubsectionHeader(context, 'AI Translation for Terms'),
          _buildControlItem(
            context,
            Icons.psychology,
            'Psychology icon',
            'Fetch AI translation (next to translation field)',
          ),
          _buildControlItem(
            context,
            Icons.add_circle_outline,
            'Auto-append',
            'Adds translation to existing content (comma-separated)',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'AI Translation for Sentences'),
          _buildControlItem(
            context,
            Icons.psychology,
            'Psychology icon',
            'Trigger AI translation (in Sentence Reader)',
          ),
          _buildControlItem(
            context,
            Icons.widgets,
            'Translation widget',
            'Opens modal with original sentence, AI translation, and retry',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'AI Settings (in Settings Screen)'),
          _buildControlItem(context, Icons.dns, 'Provider Configuration', ''),
          _buildControlItem(
            context,
            Icons.arrow_right,
            'AI Provider dropdown',
            'Select provider (OpenAI, Local OpenAI, None)',
          ),
          _buildControlItem(
            context,
            Icons.arrow_right,
            'OpenAI settings',
            'API Key field, Base URL field, Model selector',
          ),
          _buildControlItem(
            context,
            Icons.arrow_right,
            'Local OpenAI settings',
            'Endpoint URL, Model selector, API Key field',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Prompt Configuration'),
          _buildControlItem(
            context,
            Icons.text_fields,
            'Term Translation prompt',
            'Enable/disable toggle, Custom prompt editor, Reset to default, Placeholders: [term], [sentence], [language]',
          ),
          _buildControlItem(
            context,
            Icons.article,
            'Sentence Translation prompt',
            'Enable/disable toggle, Custom prompt editor, Reset to default, Placeholders: [sentence], [language]',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'AI Behavior'),
          _buildControlItem(
            context,
            Icons.block,
            'Provider "None"',
            'AI features hidden, translation disabled',
          ),
          _buildControlItem(
            context,
            Icons.visibility_off,
            'Prompt disabled',
            'Individual feature hidden even if provider configured',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Default Prompts'),
          _buildControlItem(
            context,
            Icons.code,
            'Term Translation',
            'Using the sentence "[sentence]" Translate only the following term from [language] to English: [term]. Respond with the 2 most common translations',
          ),
          _buildControlItem(
            context,
            Icons.code,
            'Sentence Translation',
            'Translate the following sentence from [language] to English: [sentence]',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildControlItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        description,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
