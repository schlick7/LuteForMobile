import 'package:flutter/material.dart';
import '../models/settings.dart';

class NewThemeDialog extends StatefulWidget {
  const NewThemeDialog({super.key});

  @override
  State<NewThemeDialog> createState() => _NewThemeDialogState();
}

class _NewThemeDialogState extends State<NewThemeDialog> {
  final _nameController = TextEditingController();
  ThemeInitMode _mode = ThemeInitMode.fromCurrent;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Theme'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Theme name',
                hintText: 'My Theme',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start From',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...ThemeInitMode.values.map((mode) {
              return RadioListTile<ThemeInitMode>(
                value: mode,
                groupValue: _mode,
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_labelForMode(mode)),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _mode = value;
                  });
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'mode': _mode,
            });
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _labelForMode(ThemeInitMode mode) {
    switch (mode) {
      case ThemeInitMode.fromDark:
        return 'Dark preset';
      case ThemeInitMode.fromLight:
        return 'Light preset';
      case ThemeInitMode.fromBlackAndWhite:
        return 'Black & white preset';
      case ThemeInitMode.fromCurrent:
        return 'Current active theme';
      case ThemeInitMode.blank:
        return 'Blank template';
    }
  }
}
