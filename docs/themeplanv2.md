# Theme System Expansion - v2 Plan


## **Objective**
Add comprehensive custom theme editor allowing users to customize all colors in the application, with live previews and intuitive organization.

## **v2 Scope**
- ✅ Full custom theme editor with all color categories
- ✅ Color picker with presets and custom hex input
- ✅ Live preview panel showing all color usages
- ✅ Status color mode toggles (background vs text) - **StatusMode enum deferred from v1**
- ✅ Reset functionality (full theme, individual sections, individual colors)
- ✅ Custom theme persistence
- ✅ Copy from Dark/Light presets

---

## **Phase 1: Custom Theme Data Model**

### **1. Modify: `lib/features/settings/models/settings.dart`**

**Changes to `ThemeSettings` class:**
- Add `AppThemeColorScheme? customColorScheme`
- Add `Map<int, StatusMode> statusModes` for status color modes (0-5, 98, 99)
- Add custom theme to `copyWith()` method
- Add to `operator ==` and `hashCode`
- Keep accent colors and themeType unchanged

```dart
class ThemeSettings {
  final ThemeType themeType;
  final Color accentLabelColor;
  final Color accentButtonColor;
  final Color? customAccentLabelColor;
  final Color? customAccentButtonColor;
  
  // New fields for v2
  final AppThemeColorScheme? customColorScheme;
  final Map<int, StatusMode> statusModes;
  
  const ThemeSettings({
    this.themeType = ThemeType.dark,
    this.accentLabelColor = const Color(0xFF1976D2),
    this.accentButtonColor = const Color(0xFF6750A4),
    this.customAccentLabelColor,
    this.customAccentButtonColor,
    this.customColorScheme,
    Map<int, StatusMode>? statusModes,
  }) : statusModes = statusModes ?? {
    0: StatusMode.text,    // Status 0 as text color (current behavior)
    1: StatusMode.background,
    2: StatusMode.background,
    3: StatusMode.background,
    4: StatusMode.background,
    5: StatusMode.background,
    98: StatusMode.background,
    99: StatusMode.background,
  };
  
  ThemeSettings copyWith({
    ThemeType? themeType,
    Color? accentLabelColor,
    Color? accentButtonColor,
    Color? customAccentLabelColor,
    Color? customAccentButtonColor,
    AppThemeColorScheme? customColorScheme,
    Map<int, StatusMode>? statusModes,
  }) {
    return ThemeSettings(
      themeType: themeType ?? this.themeType,
      accentLabelColor: accentLabelColor ?? this.accentLabelColor,
      accentButtonColor: accentButtonColor ?? this.accentButtonColor,
      customAccentLabelColor: customAccentLabelColor ?? this.customAccentLabelColor,
      customAccentButtonColor: customAccentButtonColor ?? this.customAccentButtonColor,
      customColorScheme: customColorScheme ?? this.customColorScheme,
      statusModes: statusModes ?? this.statusModes,
    );
  }

  // Add helper method to copy with statusModes only
  ThemeSettings copyWithStatusModes(Map<int, StatusMode> newStatusModes) {
    return copyWith(statusModes: newStatusModes);
  }
  }) {
    return ThemeSettings(
      themeType: themeType ?? this.themeType,
      accentLabelColor: accentLabelColor ?? this.accentLabelColor,
      accentButtonColor: accentButtonColor ?? this.accentButtonColor,
      customAccentLabelColor: customAccentLabelColor ?? this.customAccentLabelColor,
      customAccentButtonColor: customAccentButtonColor ?? this.customAccentButtonColor,
      customColorScheme: customColorScheme ?? this.customColorScheme,
      statusModes: statusModes ?? this.statusModes,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.themeType == themeType &&
        // ... existing equality checks
        other.customColorScheme == customColorScheme &&
        _mapEquals(other.statusModes, statusModes);
  }
  
  @override
  int get hashCode => Object.hash(
    themeType,
    // ... existing hash values
    customColorScheme,
    statusModes.hashCode,
  );
}

bool _mapEquals<T, U>(Map<T, U> a, Map<T, U> b) {
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}
```

---

## **Phase 2: Custom Theme Serialization**

### **2. Create: `lib/shared/theme/theme_serialization.dart`**

```dart
import 'package:flutter/material.dart';
import 'theme_definitions.dart';

/// Serialization utilities for AppThemeColorScheme
class ThemeSerialization {
  /// Serialize AppThemeColorScheme to JSON
  static Map<String, dynamic> toJson(AppThemeColorScheme scheme) {
    return {
      'textPrimary': _colorToJson(scheme.textPrimary),
      'textSecondary': _colorToJson(scheme.textSecondary),
      'textDisabled': _colorToJson(scheme.textDisabled),
      'textHeadline': _colorToJson(scheme.textHeadline),
      'textOnPrimary': _colorToJson(scheme.textOnPrimary),
      'textOnSecondary': _colorToJson(scheme.textOnSecondary),
      'onPrimary': _colorToJson(scheme.onPrimary),
      'onPrimaryContainer': _colorToJson(scheme.onPrimaryContainer),
      'onSecondary': _colorToJson(scheme.onSecondary),
      'onSecondaryContainer': _colorToJson(scheme.onSecondaryContainer),
      'onTertiary': _colorToJson(scheme.onTertiary),
      'onTertiaryContainer': _colorToJson(scheme.onTertiaryContainer),
      'background': _colorToJson(scheme.background),
      'surface': _colorToJson(scheme.surface),
      'surfaceVariant': _colorToJson(scheme.surfaceVariant),
      'surfaceContainerHighest': _colorToJson(scheme.surfaceContainerHighest),
      'bookCardBackground': _colorToJson(scheme.bookCardBackground),
      'tooltipBackground': _colorToJson(scheme.tooltipBackground),
      'success': _colorToJson(scheme.success),
      'onSuccess': _colorToJson(scheme.onSuccess),
      'warning': _colorToJson(scheme.warning),
      'onWarning': _colorToJson(scheme.onWarning),
      'error': _colorToJson(scheme.error),
      'onError': _colorToJson(scheme.onError),
      'info': _colorToJson(scheme.info),
      'onInfo': _colorToJson(scheme.onInfo),
      'connected': _colorToJson(scheme.connected),
      'disconnected': _colorToJson(scheme.disconnected),
      'aiProviderBadge': _colorToJson(scheme.aiProviderBadge),
      'localProviderBadge': _colorToJson(scheme.localProviderBadge),
      'status0': _colorToJson(scheme.status0),
      'status1': _colorToJson(scheme.status1),
      'status2': _colorToJson(scheme.status2),
      'status3': _colorToJson(scheme.status3),
      'status4': _colorToJson(scheme.status4),
      'status5': _colorToJson(scheme.status5),
      'status98': _colorToJson(scheme.status98),
      'status99': _colorToJson(scheme.status99),
      'statusHighlightedText': _colorToJson(scheme.statusHighlightedText),
      'outline': _colorToJson(scheme.outline),
      'outlineVariant': _colorToJson(scheme.outlineVariant),
      'dividerColor': _colorToJson(scheme.dividerColor),
      'audioPlayerBackground': _colorToJson(scheme.audioPlayerBackground),
      'audioPlayerIcon': _colorToJson(scheme.audioPlayerIcon),
      'audioBookmark': _colorToJson(scheme.audioBookmark),
      'audioError': _colorToJson(scheme.audioError),
      'audioErrorBackground': _colorToJson(scheme.audioErrorBackground),
    };
  }
  
  /// Deserialize AppThemeColorScheme from JSON
  static AppThemeColorScheme? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    
    try {
      return AppThemeColorScheme(
        textPrimary: _jsonToColor(json['textPrimary']),
        textSecondary: _jsonToColor(json['textSecondary']),
        textDisabled: _jsonToColor(json['textDisabled']),
        textHeadline: _jsonToColor(json['textHeadline']),
        textOnPrimary: _jsonToColor(json['textOnPrimary']),
        textOnSecondary: _jsonToColor(json['textOnSecondary']),
        onPrimary: _jsonToColor(json['onPrimary']),
        onPrimaryContainer: _jsonToColor(json['onPrimaryContainer']),
        onSecondary: _jsonToColor(json['onSecondary']),
        onSecondaryContainer: _jsonToColor(json['onSecondaryContainer']),
        onTertiary: _jsonToColor(json['onTertiary']),
        onTertiaryContainer: _jsonToColor(json['onTertiaryContainer']),
        background: _jsonToColor(json['background']),
        surface: _jsonToColor(json['surface']),
        surfaceVariant: _jsonToColor(json['surfaceVariant']),
        surfaceContainerHighest: _jsonToColor(json['surfaceContainerHighest']),
        bookCardBackground: _jsonToColor(json['bookCardBackground']),
        tooltipBackground: _jsonToColor(json['tooltipBackground']),
        success: _jsonToColor(json['success']),
        onSuccess: _jsonToColor(json['onSuccess']),
        warning: _jsonToColor(json['warning']),
        onWarning: _jsonToColor(json['onWarning']),
        error: _jsonToColor(json['error']),
        onError: _jsonToColor(json['onError']),
        info: _jsonToColor(json['info']),
        onInfo: _jsonToColor(json['onInfo']),
        connected: _jsonToColor(json['connected']),
        disconnected: _jsonToColor(json['disconnected']),
        aiProviderBadge: _jsonToColor(json['aiProviderBadge']),
        localProviderBadge: _jsonToColor(json['localProviderBadge']),
        status0: _jsonToColor(json['status0']),
        status1: _jsonToColor(json['status1']),
        status2: _jsonToColor(json['status2']),
        status3: _jsonToColor(json['status3']),
        status4: _jsonToColor(json['status4']),
        status5: _jsonToColor(json['status5']),
        status98: _jsonToColor(json['status98']),
        status99: _jsonToColor(json['status99']),
        statusHighlightedText: _jsonToColor(json['statusHighlightedText']),
        outline: _jsonToColor(json['outline']),
        outlineVariant: _jsonToColor(json['outlineVariant']),
        dividerColor: _jsonToColor(json['dividerColor']),
        audioPlayerBackground: _jsonToColor(json['audioPlayerBackground']),
        audioPlayerIcon: _jsonToColor(json['audioPlayerIcon']),
        audioBookmark: _jsonToColor(json['audioBookmark']),
        audioError: _jsonToColor(json['audioError']),
        audioErrorBackground: _jsonToColor(json['audioErrorBackground']),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Serialize Color to string
  static String _colorToJson(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
  
  /// Deserialize Color from string
  static Color _jsonToColor(dynamic value) {
    if (value is! String) return Colors.black;
    final hex = value.startsWith('#') ? value.substring(1) : value;
    return Color(int.parse(hex, radix: 16) + 0xFF000000);
  }
}
```

---

## **Phase 3: Update Settings Provider**

### **3. Modify: `lib/features/settings/providers/settings_provider.dart`**

**Changes:**
- Add storage key: `static const String _customThemeKey = 'customTheme';`
- Add storage key: `static const String _statusModesKey = 'statusModes';`
- In `loadSettings()`, load custom theme and status modes:
  ```dart
  final customThemeJson = prefs.getString(_customThemeKey);
  final statusModesJson = prefs.getString(_statusModesKey);
  
  final customColorScheme = customThemeJson != null
      ? ThemeSerialization.fromJson(jsonDecode(customThemeJson))
      : null;
  
  final statusModes = statusModesJson != null
      ? Map<int, StatusMode>.from(
          jsonDecode(statusModesJson).map(
            (key, value) => MapEntry(
              int.parse(key),
              StatusMode.values.firstWhere((e) => e.name == value),
            ),
          ),
        )
      : null;
  ```

- In `saveSettings()`, save custom theme and status modes:
  ```dart
  if (settings.themeSettings.customColorScheme != null) {
    final customThemeJson = jsonEncode(
      ThemeSerialization.toJson(settings.themeSettings.customColorScheme!)
    );
    await prefs.setString(_customThemeKey, customThemeJson);
  }
  
  final statusModesJson = jsonEncode(
    settings.themeSettings.statusModes.map(
      (key, value) => MapEntry(key.toString(), value.name),
    ),
  );
  await prefs.setString(_statusModesKey, statusModesJson);
  ```

- Add new methods:
  ```dart
  Future<void> updateCustomColorScheme(AppThemeColorScheme scheme) async {
    final updated = settings.copyWith(
      themeSettings: settings.themeSettings.copyWith(
        customColorScheme: scheme,
      ),
    );
    state = AsyncValue.data(updated);
    await _saveSettings(updated);
  }
  
  Future<void> updateStatusMode(int status, StatusMode mode) async {
    final currentModes = Map<int, StatusMode>.from(
      settings.themeSettings.statusModes
    );
    currentModes[status] = mode;
    
    final updated = settings.copyWith(
      themeSettings: settings.themeSettings.copyWith(
        statusModes: currentModes,
      ),
    );
    state = AsyncValue.data(updated);
    await _saveSettings(updated);
  }
  
  Future<void> copyFromPreset(ThemeType type) async {
    final preset = type == ThemeType.light
        ? lightThemePreset
        : darkThemePreset;
    
    await updateCustomColorScheme(preset);
  }
  
  Future<void> resetCustomTheme() async {
    final updated = settings.copyWith(
      themeSettings: settings.themeSettings.copyWith(
        customColorScheme: null,
        statusModes: const {
          0: StatusMode.text,
          1: StatusMode.background,
          2: StatusMode.background,
          3: StatusMode.background,
          4: StatusMode.background,
          5: StatusMode.background,
          98: StatusMode.background,
          99: StatusMode.background,
        },
      ),
    );
    state = AsyncValue.data(updated);
    await _saveSettings(updated);
  }
  ```

---

## **Phase 4: Custom Theme Editor UI**

### **4. Create: `lib/features/settings/widgets/custom_theme_editor.dart`**

**Main Widget Structure:**
```dart
class CustomThemeEditor extends ConsumerStatefulWidget {
  @override
  ConsumerState<CustomThemeEditor> createState() => _CustomThemeEditorState();
}

class _CustomThemeEditorState extends ConsumerState<CustomThemeEditor> {
  late AppThemeColorScheme currentScheme;
  
  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    currentScheme = settings.themeSettings.customColorScheme ?? 
                    darkThemePreset; // Default to dark
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Theme'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _showResetDialog(),
            tooltip: 'Reset to default',
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: () => _showCopyPresetDialog(),
            tooltip: 'Copy from preset',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveTheme(),
            tooltip: 'Save theme',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildTextColorsSection(),
                _buildBackgroundColorsSection(),
                _buildSemanticColorsSection(),
                _buildStatusColorsSection(),
                _buildProviderColorsSection(),
                _buildBorderColorsSection(),
                _buildAudioPlayerColorsSection(),
              ],
            ),
          ),
          _buildLivePreviewPanel(),
        ],
      ),
    );
  }
}
```

### **5. Create: `lib/features/settings/widgets/theme_editor_sections/text_colors_section.dart`**

```dart
class _TextColorsSection extends StatelessWidget {
  final AppThemeColorScheme scheme;
  final Function(Color, String) onColorChanged;
  
  @override
  Widget build(BuildContext context) {
    return _buildSection(
      'Text Colors',
      Icons.text_fields,
      [
        _ColorEditor(
          label: 'Primary Text',
          description: 'Main body text color',
          color: scheme.textPrimary,
          preview: Text(
            'Sample primary text',
            style: TextStyle(color: scheme.textPrimary, fontSize: 16),
          ),
          onChanged: (color) => onColorChanged(color, 'textPrimary'),
        ),
        _ColorEditor(
          label: 'Secondary Text',
          description: 'Subtitles and metadata',
          color: scheme.textSecondary,
          preview: Text(
            'Sample secondary text',
            style: TextStyle(color: scheme.textSecondary, fontSize: 14),
          ),
          onChanged: (color) => onColorChanged(color, 'textSecondary'),
        ),
        _ColorEditor(
          label: 'Disabled Text',
          description: 'Disabled element text',
          color: scheme.textDisabled,
          preview: Text(
            'Sample disabled text',
            style: TextStyle(color: scheme.textDisabled, fontSize: 14),
          ),
          onChanged: (color) => onColorChanged(color, 'textDisabled'),
        ),
        _ColorEditor(
          label: 'Headline Text',
          description: 'Heading and title text',
          color: scheme.textHeadline,
          preview: Text(
            'Sample headline',
            style: TextStyle(color: scheme.textHeadline, fontSize: 24),
          ),
          onChanged: (color) => onColorChanged(color, 'textHeadline'),
        ),
        _ColorEditor(
          label: 'Text on Primary',
          description: 'Text on primary colored backgrounds',
          color: scheme.textOnPrimary,
          preview: Container(
            color: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.all(8),
            child: Text(
              'Text on primary',
              style: TextStyle(color: scheme.textOnPrimary),
            ),
          ),
          onChanged: (color) => onColorChanged(color, 'textOnPrimary'),
        ),
        _ColorEditor(
          label: 'Text on Secondary',
          description: 'Text on secondary colored backgrounds',
          color: scheme.textOnSecondary,
          preview: Container(
            color: Theme.of(context).colorScheme.secondary,
            padding: EdgeInsets.all(8),
            child: Text(
              'Text on secondary',
              style: TextStyle(color: scheme.textOnSecondary),
            ),
          ),
          onChanged: (color) => onColorChanged(color, 'textOnSecondary'),
        ),
      ],
    );
  }
}
```

### **6. Create: `lib/features/settings/widgets/theme_editor_sections/background_colors_section.dart`**

Similar structure to text colors section, with previews showing:
- Background preview with overlay text
- Card preview
- Surface container preview
- Book card preview
- Tooltip preview

### **7. Create: `lib/features/settings/widgets/theme_editor_sections/semantic_colors_section.dart`**

Success, warning, error, info, connected, disconnected colors with relevant icons and text previews.

### **8. Create: `lib/features/settings/widgets/theme_editor_sections/status_colors_section.dart`**

```dart
class _StatusColorsSection extends StatelessWidget {
  final AppThemeColorScheme scheme;
  final Map<int, StatusMode> statusModes;
  final Function(Color, int) onColorChanged;
  final Function(StatusMode, int) onModeChanged;
  
  @override
  Widget build(BuildContext context) {
    return _buildSection(
      'Status Colors',
      Icons.star,
      [
        _StatusColorEditor(
          status: 0,
          label: 'Unknown (0)',
          description: 'Words not yet seen',
          color: scheme.status0,
          mode: statusModes[0] ?? StatusMode.text,
          onChanged: (color) => onColorChanged(color, 0),
          onModeChanged: (mode) => onModeChanged(mode, 0),
        ),
        _StatusColorEditor(
          status: 1,
          label: 'Learning (1)',
          description: 'Hardest words',
          color: scheme.status1,
          mode: statusModes[1] ?? StatusMode.background,
          onChanged: (color) => onColorChanged(color, 1),
          onModeChanged: (mode) => onModeChanged(mode, 1),
        ),
        _StatusColorEditor(
          status: 2,
          label: 'Learning (2)',
          description: 'Difficult words',
          color: scheme.status2,
          mode: statusModes[2] ?? StatusMode.background,
          onChanged: (color) => onColorChanged(color, 2),
          onModeChanged: (mode) => onModeChanged(mode, 2),
        ),
        _StatusColorEditor(
          status: 3,
          label: 'Learning (3)',
          description: 'Medium difficulty',
          color: scheme.status3,
          mode: statusModes[3] ?? StatusMode.background,
          onChanged: (color) => onColorChanged(color, 3),
          onModeChanged: (mode) => onModeChanged(mode, 3),
        ),
        _StatusColorEditor(
          status: 4,
          label: 'Learning (4)',
          description: 'Easier words',
          color: scheme.status4,
          mode: statusModes[4] ?? StatusMode.background,
          onChanged: (color) => onColorChanged(color, 4),
          onModeChanged: (mode) => onModeChanged(mode, 4),
        ),
        _StatusColorEditor(
          status: 5,
          label: 'Learning (5)',
          description: 'Almost known',
          color: scheme.status5,
          mode: statusModes[5] ?? StatusMode.background,
          onChanged: (color) => onColorChanged(color, 5),
          onModeChanged: (mode) => onModeChanged(mode, 5),
        ),
        _StatusColorEditor(
          status: 98,
          label: 'Ignored (98)',
          description: 'Ignored terms',
          color: scheme.status98,
          mode: statusModes[98] ?? StatusMode.background,
          onChanged: (color) => onColorChanged(color, 98),
          onModeChanged: (mode) => onModeChanged(mode, 98),
        ),
        _StatusColorEditor(
          status: 99,
          label: 'Known (99)',
          description: 'Known words',
          color: scheme.status99,
          mode: statusModes[99] ?? StatusMode.background,
          onChanged: (color) => onColorChanged(color, 99),
          onModeChanged: (mode) => onModeChanged(mode, 99),
        ),
      ],
    );
  }
}
```

### **9. Create: `lib/features/settings/widgets/theme_editor_sections/status_mode_toggle.dart`**

```dart
class _StatusModeToggle extends StatelessWidget {
  final StatusMode mode;
  final Function(StatusMode) onChanged;
  
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StatusMode>(
      segments: [
        ButtonSegment(
          value: StatusMode.background,
          label: Text('Background'),
          icon: Icon(Icons.format_color_fill),
        ),
        ButtonSegment(
          value: StatusMode.text,
          label: Text('Text Color'),
          icon: Icon(Icons.text_fields),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (Set<StatusMode> selected) {
        onChanged(selected.first);
      },
    );
  }
}
```

### **10. Create: `lib/features/settings/widgets/theme_editor_sections/color_editor.dart`**

```dart
class _ColorEditor extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final Widget preview;
  final Function(Color) onChanged;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              _ColorPicker(
                color: color,
                onChanged: onChanged,
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: preview),
          ),
        ],
      ),
    );
  }
}
```

### **11. Create: `lib/features/settings/widgets/theme_editor_sections/color_picker.dart`**

```dart
class _ColorPicker extends StatelessWidget {
  final Color color;
  final Function(Color) onChanged;
  
  static final List<Color> presetColors = [
    Color(0xFF1976D2), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9E9E80), // Brown
    Color(0xFF6750A4), // Purple
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Grey
    Color(0xFF49454F), // Light gray
    Color(0xFF938F99), // Lighter gray
    Color(0xFFBA1A1A), // Red
    Color(0xFF2C2C2C), // Dark gray
    Color(0xFF1A1A1A), // Near black
    Color(0xFFE6E1E5), // Light gray
    Color(0xFFFFFFFF), // White
  ];
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...presetColors.map((preset) {
          final isSelected = preset.value == color.value;
          return InkWell(
            onTap: () => onChanged(preset),
            child: Container(
              width: 32,
              height: 32,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: preset,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isSelected 
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          );
        }),
        InkWell(
          onTap: () => _showCustomColorDialog(context),
          child: Container(
            width: 32,
            height: 32,
            margin: EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1,
              ),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
  
  void _showCustomColorDialog(BuildContext context) {
    final controller = TextEditingController(
      text: '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom Color'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Color Hex Code',
            hintText: '#RRGGBB',
            border: OutlineInputBorder(),
          ),
          maxLength: 7,
          onChanged: (value) {
            // Update preview
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final hexCode = controller.text.trim();
              if (hexCode.startsWith('#') && hexCode.length == 7) {
                final parsedColor = Color(
                  int.parse(hexCode.substring(1), radix: 16) + 0xFF000000
                );
                onChanged(parsedColor);
                Navigator.pop(context);
              }
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }
}
```

### **12. Create: `lib/features/settings/widgets/theme_editor_sections/live_preview_panel.dart`**

```dart
class _LivePreviewPanel extends StatelessWidget {
  final AppThemeColorScheme scheme;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: scheme.background,
        border: Border(
          top: BorderSide(color: scheme.outline),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Text samples
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text Samples',
                    style: TextStyle(
                      color: scheme.textHeadline,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Primary text example',
                    style: TextStyle(color: scheme.textPrimary),
                  ),
                  Text(
                    'Secondary text example',
                    style: TextStyle(color: scheme.textSecondary),
                  ),
                  Text(
                    'Disabled text example',
                    style: TextStyle(color: scheme.textDisabled),
                  ),
                ],
              ),
            ),
            Divider(color: scheme.dividerColor),
            // Status samples
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Colors',
                    style: TextStyle(
                      color: scheme.textHeadline,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(6, (index) {
                      return Chip(
                        label: Text('Status $index'),
                        backgroundColor: scheme.getStatusColor('$index'),
                      );
                    }),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('Ignored'),
                        backgroundColor: scheme.status98,
                      ),
                      Chip(
                        label: Text('Known'),
                        backgroundColor: scheme.status99,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: scheme.dividerColor),
            // Book card preview
            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.bookCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline),
                ),
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Title',
                      style: TextStyle(
                        color: scheme.textHeadline,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Book Author',
                      style: TextStyle(
                        color: scheme.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: scheme.success, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '50% complete',
                          style: TextStyle(color: scheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: scheme.dividerColor),
            // Semantic colors
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSemanticIcon(Icons.check_circle, 'Success', scheme.success),
                  _buildSemanticIcon(Icons.warning, 'Warning', scheme.warning),
                  _buildSemanticIcon(Icons.error, 'Error', scheme.error),
                  _buildSemanticIcon(Icons.info, 'Info', scheme.info),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSemanticIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }
}
```

---

## **Phase 5: Update Theme Selector**

### **13. Modify: `lib/features/settings/widgets/theme_selector_screen.dart`**

**Changes:**
- Enable Custom theme card
- Add navigation to CustomThemeEditor
- Add "Edit" button for custom theme

```dart
Widget _buildThemeCard(
  BuildContext context,
  ThemeType type,
  String title,
  String description,
  {bool enabled = true, bool isCurrentThemeType = false}
) {
  final settings = ref.watch(settingsProvider);
  final hasCustomTheme = settings.themeSettings.customColorScheme != null;
  
  return Card(
    margin: EdgeInsets.all(8),
    elevation: isCurrentThemeType ? 4 : 1,
    child: InkWell(
      onTap: enabled ? () => _selectTheme(type) : null,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _getThemeIcon(type),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrentThemeType)
                  Icon(Icons.check_circle, color: Colors.green),
                if (type == ThemeType.custom && hasCustomTheme)
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomThemeEditor(),
                        ),
                      );
                    },
                  ),
              ],
            ),
            SizedBox(height: 12),
            _buildPreview(type),
          ],
        ),
      ),
    ),
  );
}

void _selectTheme(ThemeType type) {
  if (type == ThemeType.custom) {
    // Navigate to custom theme editor
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomThemeEditor()),
    );
  } else {
    ref.read(settingsProvider.notifier).updateThemeType(type);
  }
}
```

---

## **Phase 6: Update Theme Application**

### **14. Modify: `lib/shared/theme/app_theme.dart`**

**Changes:**
- Update theme methods to use custom color scheme when available
- Update status color methods to respect status modes

```dart
static AppThemeColorScheme _getThemePreset(
  ThemeSettings themeSettings,
) {
  if (themeSettings.themeType == ThemeType.custom &&
      themeSettings.customColorScheme != null) {
    return themeSettings.customColorScheme!;
  } else if (themeSettings.themeType == ThemeType.light) {
    return lightThemePreset;
  } else {
    return darkThemePreset;
  }
}

static ThemeData _buildTheme(
  ThemeSettings themeSettings,
  AppThemeColorScheme preset,
  Brightness brightness,
) {
  final colorScheme = brightness == Brightness.light
      ? ColorScheme.light(...)
      : ColorScheme.dark(...);
  
  // Map preset colors to theme
  // ... existing mapping logic
  
  return ThemeData(
    // ... existing theme setup
    extensions: [
      CustomThemeExtension(
        colors: CustomThemeColors(
          accentLabelColor: themeSettings.accentLabelColor,
          accentButtonColor: themeSettings.accentButtonColor,
        ),
      ),
      AppThemeExtension(
        colorScheme: preset,
        statusModes: themeSettings.statusModes,
      ),
    ],
  );
}
```

### **15. Modify: `lib/shared/theme/theme_extensions.dart`**

**Changes:**
- Add status mode awareness to status color getters

```dart
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final AppThemeColorScheme colorScheme;
  final Map<int, StatusMode> statusModes;
  
  const AppThemeExtension({
    required this.colorScheme,
    required this.statusModes,
  });
  
  // ... copyWith, lerp, etc.
}

extension AppColorSchemeExtension on ColorScheme {
  AppThemeExtension get appThemeExtension {
    return extension<AppThemeExtension>() ??
        const AppThemeExtension(
          colorScheme: darkThemePreset,
          statusModes: {},
        );
  }
  
  AppThemeColorScheme get appColorScheme => appThemeExtension.colorScheme;
  Map<int, StatusMode> get statusModes => appThemeExtension.statusModes;
  
  Color getStatusTextColor(String status) {
    final statusNum = int.tryParse(status) ?? 0;
    final mode = statusModes[statusNum] ?? 
                 (statusNum == 0 ? StatusMode.text : StatusMode.background);
    
    if (mode == StatusMode.text) {
      return appColorScheme.getStatusColor(status);
    } else if (['1', '2', '3', '4', '5'].contains(status)) {
      return appColorScheme.statusHighlightedText;
    } else {
      return onSurface;
    }
  }
  
  Color? getStatusBackgroundColor(String status) {
    final statusNum = int.tryParse(status) ?? 0;
    final mode = statusModes[statusNum] ?? 
                 (statusNum == 0 ? StatusMode.text : StatusMode.background);
    
    if (mode == StatusMode.background) {
      return appColorScheme.getStatusColor(status);
    } else {
      return null;
    }
  }
}
```

---

## **v2 File Summary**

### **New Files (11)**
1. `lib/shared/theme/theme_serialization.dart` - JSON serialization
2. `lib/features/settings/widgets/custom_theme_editor.dart` - Main editor
3. `lib/features/settings/widgets/theme_editor_sections/text_colors_section.dart`
4. `lib/features/settings/widgets/theme_editor_sections/background_colors_section.dart`
5. `lib/features/settings/widgets/theme_editor_sections/semantic_colors_section.dart`
6. `lib/features/settings/widgets/theme_editor_sections/status_colors_section.dart`
7. `lib/features/settings/widgets/theme_editor_sections/status_mode_toggle.dart`
8. `lib/features/settings/widgets/theme_editor_sections/color_editor.dart`
9. `lib/features/settings/widgets/theme_editor_sections/color_picker.dart`
10. `lib/features/settings/widgets/theme_editor_sections/live_preview_panel.dart`
11. `lib/features/settings/widgets/theme_editor_sections/provider_colors_section.dart`
12. `lib/features/settings/widgets/theme_editor_sections/border_colors_section.dart`
13. `lib/features/settings/widgets/theme_editor_sections/audio_player_colors_section.dart`

### **Modified Files (5)**
1. `lib/features/settings/models/settings.dart` - Add custom theme fields
2. `lib/features/settings/providers/settings_provider.dart` - Save/load custom themes
3. `lib/features/settings/widgets/theme_selector_screen.dart` - Enable custom theme
4. `lib/shared/theme/app_theme.dart` - Use custom theme when available
5. `lib/shared/theme/theme_extensions.dart` - Status mode awareness

### **Updates from v1 Deferred to v2**
1. `StatusMode` enum - Moved from v1 definitions, now used in custom theme editor
2. Theme preview widgets in theme selector - Added as live preview panel in v2
3. `ThemeType.custom` enum value - Added to enable custom theme selection

---

## **v2 Testing Checklist**

### **Custom Theme Editor**
- [ ] All color categories display correctly
- [ ] All color pickers work
- [ ] Preset colors apply correctly
- [ ] Custom hex input works
- [ ] Live preview updates in real-time
- [ ] Reset to default works
- [ ] Copy from preset works
- [ ] Save theme works
- [ ] Individual color reset works

### **Status Modes**
- [ ] Status mode toggles work
- [ ] Status as background displays correctly
- [ ] Status as text color displays correctly
- [ ] Status 0 as text (default) works
- [ ] Status 1-5 as background (default) works
- [ ] Status modes persist after save

### **Theme Application**
- [ ] Custom theme applies when selected
- [ ] Custom theme overrides dark/light presets
- [ ] Switching to dark/light reverts to preset
- [ ] All screens use custom theme colors
- [ ] Status colors use correct modes
- [ ] All UI elements render correctly

### **Persistence**
- [ ] Custom theme saves correctly
- [ ] Custom theme loads after app restart
- [ ] Status modes save correctly
- [ ] Status modes load after app restart
- [ ] JSON serialization works
- [ ] JSON deserialization works

### **Reset Functionality**
- [ ] Full theme reset works
- [ ] Individual section reset works
- [ ] Individual color reset works
- [ ] Reset to dark preset works
- [ ] Reset to light preset works

### **Copy from Preset**
- [ ] Copy from dark works
- [ ] Copy from light works
- [ ] Copy maintains status modes
- [ ] Copy can be modified independently

### **UI/UX**
- [ ] Live preview panel shows all color usages
- [ ] Color picker is easy to use
- [ ] Section organization is intuitive
- [ ] Navigation is smooth
- [ ] Save button indicates unsaved changes
- [ ] Reset dialog works correctly

### **Edge Cases**
- [ ] Invalid hex codes are rejected
- [ ] Transparent status (98) works in both modes
- [ ] All status modes work correctly
- [ ] Opacity values are preserved
- [ ] Custom theme with missing fields defaults correctly

---

## **v2 Implementation Order**

1. Update `settings.dart` model with custom theme fields
2. Create `theme_serialization.dart`
3. Update `settings_provider.dart` with custom theme save/load
4. Create `color_picker.dart` widget
5. Create `color_editor.dart` widget
6. Create `status_mode_toggle.dart` widget
7. Create `text_colors_section.dart`
8. Create `background_colors_section.dart`
9. Create `semantic_colors_section.dart`
10. Create `status_colors_section.dart`
11. Create other color sections
12. Create `live_preview_panel.dart`
13. Create `custom_theme_editor.dart` main widget
14. Update `theme_selector_screen.dart` to enable custom theme
15. Update `app_theme.dart` to use custom theme
16. Update `theme_extensions.dart` for status modes
17. Test all functionality

---

## **Future Enhancements (Beyond v2)**

**Deferred from v1:**
1. **Theme Preview Widgets in Theme Selector**
   - Show samples of text, colors, status badges in theme selector
   - Visual preview of Dark/Light themes before selecting
   - Currently v1 has simple RadioListTile selection only

2. **StatusMode Enum**
   - Added to v1 definitions but not used until v2
   - Enables toggling between background highlight vs text color for status colors
   - Status 0 defaults to text mode, others default to background mode

3. **More Preset Themes**
   - Sepia theme for classic reading experience
   - High contrast theme for accessibility
   - Blue light filter theme for night reading

2. **Theme Import/Export**
   - Share custom themes as JSON files
   - Import themes from community

3. **Color Contrast Validation**
   - Warn users about unreadable combinations
   - Suggest better colors

4. **Advanced Color Pickers**
   - HSV/HSL color wheel
   - Eye dropper tool
   - Color palettes

5. **Theme Preview Screenshots**
   - Show full screen preview of theme
   - Preview on actual app screens

6. **Auto Theme Switching**
   - Switch between dark/light based on time
   - Switch based on system setting

7. **Per-Book Themes**
   - Different themes for different books
   - Language-specific themes

8. **Animated Theme Transitions**
   - Smooth transitions when switching themes
   - Theme transition animations
