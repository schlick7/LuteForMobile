import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/reader/widgets/reader_screen.dart';
import 'package:lute_for_mobile/features/reader/widgets/reader_drawer_settings.dart';
import 'package:lute_for_mobile/features/settings/widgets/settings_screen.dart';
import 'package:lute_for_mobile/features/books/widgets/books_screen.dart';
import 'package:lute_for_mobile/features/books/widgets/books_drawer_settings.dart';
import 'package:lute_for_mobile/shared/theme/app_theme.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/shared/widgets/app_drawer.dart';

final navigationProvider = Provider<NavigationController>((ref) {
  return NavigationController();
});

class NavigationController {
  final List<Function(int, int)> _readerListeners = [];
  final List<Function(int)> _screenListeners = [];

  void addReaderListener(Function(int, int) listener) {
    _readerListeners.add(listener);
  }

  void removeReaderListener(Function(int, int) listener) {
    _readerListeners.remove(listener);
  }

  void addScreenListener(Function(int) listener) {
    _screenListeners.add(listener);
  }

  void removeScreenListener(Function(int) listener) {
    _screenListeners.remove(listener);
  }

  void navigateToReader(int bookId, int pageNum) {
    for (final listener in _readerListeners) {
      listener(bookId, pageNum);
    }
  }

  void navigateToScreen(int index) {
    for (final listener in _screenListeners) {
      listener(index);
    }
  }
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    print(
      'DEBUG: App.build called, themeSettings.accentLabelColor: ${themeSettings.accentLabelColor}',
    );
    return MaterialApp(
      title: 'LuteForMobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(themeSettings),
      darkTheme: AppTheme.darkTheme(themeSettings),
      themeMode: ThemeMode.system,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ReaderScreenState> _readerKey =
      GlobalKey<ReaderScreenState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDrawerSettings();
    });
    ref.read(navigationProvider).addReaderListener(_handleNavigateToReader);
    ref.read(navigationProvider).addScreenListener(_handleNavigateToScreen);
  }

  @override
  void dispose() {
    ref.read(navigationProvider).removeReaderListener(_handleNavigateToReader);
    ref.read(navigationProvider).removeScreenListener(_handleNavigateToScreen);
    super.dispose();
  }

  void _handleNavigateToReader(int bookId, int pageNum) {
    if (_readerKey.currentState != null) {
      _readerKey.currentState!.loadBook(bookId, pageNum);
    }
    setState(() {
      _currentIndex = 0;
    });
    _updateDrawerSettings();
  }

  void _handleNavigateToScreen(int index) {
    setState(() {
      _currentIndex = index;
    });
    _updateDrawerSettings();
  }

  void _updateDrawerSettings() {
    switch (_currentIndex) {
      case 0:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(const ReaderDrawerSettings());
        break;
      case 1:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(const BooksDrawerSettings());
        break;
      case 2:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(null);
        break;
      default:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
          _updateDrawerSettings();
          if (index == 0 && _readerKey.currentState != null) {
            _readerKey.currentState!.reloadPage();
          }
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ReaderScreen(key: _readerKey, scaffoldKey: _scaffoldKey),
          BooksScreen(scaffoldKey: _scaffoldKey),
          SettingsScreen(scaffoldKey: _scaffoldKey),
        ],
      ),
    );
  }
}
