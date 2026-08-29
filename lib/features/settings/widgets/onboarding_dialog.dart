import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// What the user chose on the first-launch onboarding.
enum OnboardingChoice {
  /// Connect to a Lute server they already run elsewhere.
  existing,

  /// Run the integrated on-device server bundled in the app.
  integrated,
}

/// First-launch chooser: "how do you want to use Lute?"
///
/// Shown exactly once (see `onboarding_completed`). The integrated
/// option only makes sense on Android, where the server is bundled;
/// on other platforms only the "existing server" option is offered.
class OnboardingDialog extends StatelessWidget {
  const OnboardingDialog({super.key});

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      // Force a choice so the user isn't dropped into a state they
      // didn't pick.
      canPop: false,
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Welcome to Lute',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'How would you like to use Lute? You can change '
                  'this any time in Settings.',
                ),
                const SizedBox(height: 16),
                _ChoiceButton(
                  icon: Icons.dns,
                  title: 'Connect to an existing Lute server',
                  subtitle:
                      'Use a Lute server you already run (on your '
                      'computer, a NAS, etc.). You\'ll enter its URL.',
                  onTap: () =>
                      Navigator.of(context).pop(OnboardingChoice.existing),
                ),
                if (_isAndroid) ...[
                  const SizedBox(height: 12),
                  _ChoiceButton(
                    icon: Icons.smartphone,
                    title: 'Use the on-device server',
                    subtitle:
                        'Run Lute entirely on this phone — no separate '
                        'server needed. You\'ll pick where backups are '
                        'saved so your data survives app removal.',
                    onTap: () =>
                        Navigator.of(context).pop(OnboardingChoice.integrated),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 30, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience function for showing the onboarding chooser. Returns
/// the user's choice, or null if it couldn't be shown.
Future<OnboardingChoice?> showOnboardingDialog(BuildContext context) {
  return showDialog<OnboardingChoice>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const OnboardingDialog(),
  );
}