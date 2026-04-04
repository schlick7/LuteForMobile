import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger/widget_logger.dart';
import '../../../shared/theme/theme_extensions.dart';
import '../../../shared/widgets/app_bar_leading.dart';

class HelpScreen extends ConsumerWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  static int _buildCount = 0;

  const HelpScreen({super.key, this.scaffoldKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _buildCount++;
    WidgetLogger.logRebuild('HelpScreen', _buildCount);

    return Scaffold(
      appBar: AppBar(
        leading: AppBarLeading(scaffoldKey: scaffoldKey),
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
              const SizedBox(height: 8),
              _buildPerformanceSection(context),
              if (!kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android) ...[
                const SizedBox(height: 8),
                _buildTermuxSection(context),
              ],
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
            'Mark all terms on page as all known',
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
            Icons.touch_app,
            'Triple-tap word',
            'Mark word as Known (status 99). Must be enabled in Settings',
          ),
          _buildControlItem(
            context,
            Icons.read_more,
            'Long-press word',
            'Hold, then release on one word to show sentence translation',
          ),
          _buildControlItem(
            context,
            Icons.gesture,
            'Long-press and drag',
            'Select multiple adjacent terms, then release to open a multi-term form',
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
          _buildControlItem(
            context,
            Icons.linear_scale,
            'Long-press page indicator (top right)',
            'Open page seekbar popup to jump to any page',
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
            'Fetch AI translations',
          ),
          _buildControlItem(
            context,
            Icons.add_circle_outline,
            'Suggestion chips',
            'Shown when Auto Add is off. Tap a chip to add that translation',
          ),
          _buildControlItem(
            context,
            Icons.add_circle_outline,
            'Auto Add AI Translations',
            'Immediately appends new AI translations to the field',
          ),
          _buildControlItem(
            context,
            Icons.flash_on,
            'Auto Fetch for Status 0',
            'Automatically fetches AI translations when opening a new term with status 0',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'AI Dictionary Tabs'),
          _buildControlItem(
            context,
            Icons.translate,
            'Translation tab',
            'Shows AI-generated term translation',
          ),
          _buildControlItem(
            context,
            Icons.auto_stories,
            'Explanation tab',
            'Shows AI-generated term explanation/definition',
          ),
          _buildControlItem(
            context,
            Icons.add_circle_outline,
            'Add to Translation',
            'Adds a single AI translation from the AI tab to the term form field',
          ),
          _buildControlItem(
            context,
            Icons.add,
            'More button',
            'Requests additional distinct AI translations',
          ),
          _buildControlItem(
            context,
            Icons.refresh,
            'Refresh/Retry',
            'Retries failed AI requests or refreshes the explanation tab',
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
            Icons.touch_app,
            'Triple-tap word',
            'Mark word as Known (status 99). Must be enabled in Settings',
          ),
          _buildControlItem(
            context,
            Icons.read_more,
            'Long-press word',
            'Hold, then release on one word to show sentence translation',
          ),
          _buildControlItem(
            context,
            Icons.gesture,
            'Long-press and drag',
            'Select multiple adjacent terms, then release to open a multi-term form',
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Open by long-pressing term',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: context.appColorScheme.text.secondary,
              ),
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
            'Suggestion chips',
            'When Auto Add is off, new AI translations appear as tappable chips above the field',
          ),
          _buildControlItem(
            context,
            Icons.playlist_add,
            'Auto Add AI Translations',
            'Adds new AI translations directly into the translation field',
          ),
          _buildControlItem(
            context,
            Icons.flash_on,
            'Auto Fetch for Status 0',
            'Automatically runs term translation for newly opened status 0 terms',
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
            Icons.auto_stories,
            'Term Explanation prompt',
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
            'These prompts may need adjustment depending on the model used -- Translate only the target [language] term "[term]" into English. Sentence for disambiguation only: "[sentence]". Return exactly 2 distinct translations. Translate only "[term]". Do not absorb adjacent words into the translation. Do not expand names or noun phrases. Keep each translation to 1-4 words. Prefer lexical translations over paraphrases. If the target itself carries tense, aspect, politeness, or an attached pronoun, that meaning may appear in the translation. If the target does not carry that meaning by itself, do not import it from the sentence. The second translation must be a real close alternative, not a joke, duplicate, or capitalization variant. Output only: translation1, translation2.',
          ),
          _buildControlItem(
            context,
            Icons.code,
            'Sentence Translation',
            'These Prompts will need adjusted depending on the LLM model used -- Translate the following sentence from [language] to English: [sentence]',
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'Performance & Troubleshooting',
            Icons.bug_report,
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Book Stats Configuration'),
          _buildControlItem(
            context,
            Icons.calculate,
            'Calc Sample Size',
            'Pages sampled when calculating book stats (1-500). Lower = faster. Lower this is you lose server connection on launch',
          ),
          _buildControlItem(
            context,
            Icons.layers,
            'Pages to Process at Once',
            'Batch size for stats refresh (1-5). Lower take long but reduce server load',
          ),
          _buildControlItem(
            context,
            Icons.timer,
            'Cooldown Before Refresh',
            'Hours between auto-refresh (1-336). Prevents excessive recalculation',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Tooltip Caching'),
          _buildControlItem(
            context,
            Icons.cached,
            'Enable Tooltip Caching',
            'Cache term tooltips for 48 hours. Significantly speeds up tooltip loading, especially on slow connections',
          ),
          _buildControlItem(
            context,
            Icons.speed,
            'Tooltip Batch Size',
            'Max concurrent tooltip fetches (1-10). Higher = faster but more server load',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Known Terms Display'),
          _buildControlItem(
            context,
            Icons.visibility,
            'Show Known Terms Count',
            'This is performance heavy, if you are having problems loading into books try disabling this',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Swipe Navigation'),
          _buildControlItem(
            context,
            Icons.swipe,
            'Enable Swipe Navigation',
            'Toggle swipe gestures for page navigation. If you experience issues with pages turning unexpectedly between app launches, try disabling this',
          ),
          _buildControlItem(
            context,
            Icons.check_circle_outline,
            'Mark Pages as Read When Swiping',
            'Automatically mark pages as read when navigating via swipe gestures',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Location'),
          _buildControlItem(
            context,
            Icons.settings,
            'Settings',
            'Book Stats: Settings > Book Stats Settings. Tooltip Caching & Batch Size & Known Terms: Settings > Reading Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildTermuxSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'Termux Integration', Icons.terminal),
          const Divider(),
          _buildSubsectionHeader(context, 'What is Termux'),
          _buildControlItem(
            context,
            Icons.info,
            'OnDevice Server',
            'Terminal emulator for Android that runs Lute3 server locally on your device',
          ),
          _buildControlItem(
            context,
            Icons.offline_bolt,
            '"Offline" Functionality',
            'Full Lute3 features without needing an external computer',
          ),
          _buildControlItem(
            context,
            Icons.backup,
            'Backup/Restore',
            'Built-in backup and restore capabilities for your data',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Requirements'),
          _buildControlItem(
            context,
            Icons.phone_android,
            'Android Device',
            'Termux integration is only available on Android APK',
          ),
          _buildControlItem(
            context,
            Icons.download,
            'Termux App',
            'Must be installed from F-Droid (not Play Store)',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Backup & Restore Locations'),
          _buildControlItem(
            context,
            Icons.folder,
            'Database Path',
            '/data/data/com.termux/files/home/.local/share/Lute3/lute.db',
          ),
          _buildControlItem(
            context,
            Icons.backup,
            'Backup Path',
            'After Restoring a database file from another system it needs to be updated with the correct backup location. If it does not happen automatically then this is the default location: /data/data/com.termux/files/home/.local/share/Lute3/backups',
          ),
          _buildControlItem(
            context,
            Icons.computer,
            'Desktop Path',
            'Find in Lute3 under "About > Version and Software Info" (Data path line)',
          ),
          const Divider(),
          _buildSubsectionHeader(context, 'Important Notes'),
          _buildControlItem(
            context,
            Icons.warning,
            'Switching to Desktop Server',
            'To restore back to a computer server, manually overwrite lute.db with your backup. See: luteorg.github.io/lute-manual/backup/restore.html',
          ),
          _buildControlItem(
            context,
            Icons.settings,
            'Setup',
            'Go to Settings > Termux Integration for installation and configuration',
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
        color: context.appColorScheme.material3.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.appColorScheme.text.onPrimary, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.appColorScheme.text.onPrimary,
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
