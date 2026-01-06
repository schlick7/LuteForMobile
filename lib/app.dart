import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/reader/widgets/reader_screen.dart';
import 'package:lute_for_mobile/features/reader/widgets/reader_drawer_settings.dart';
import 'package:lute_for_mobile/features/reader/widgets/sentence_reader_screen.dart';

import 'package:lute_for_mobile/features/settings/widgets/settings_screen.dart';
import 'package:lute_for_mobile/features/settings/widgets/help_screen.dart';
import 'package:lute_for_mobile/features/books/widgets/books_screen.dart';
import 'package:lute_for_mobile/features/books/widgets/books_drawer_settings.dart';
import 'package:lute_for_mobile/shared/theme/app_theme.dart';
import 'package:lute_for_mobile/shared/theme/theme_definitions.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/shared/widgets/app_drawer.dart';
import 'package:lute_for_mobile/features/books/providers/books_provider.dart';

class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

final navigationProvider = Provider<NavigationController>((ref) {
  return NavigationController();
});

class CurrentScreenRouteNotifier extends Notifier<String> {
  @override
  String build() {
    return 'reader';
  }

  void setRoute(String route) {
    state = route;
  }
}

final currentScreenRouteProvider =
    NotifierProvider<CurrentScreenRouteNotifier, String>(() {
      return CurrentScreenRouteNotifier();
    });

class NavigationController {
  final List<Function(int, int?)> _readerListeners = [];
  final List<Function(int)> _screenListeners = [];

  void addReaderListener(Function(int, int?) listener) {
    _readerListeners.add(listener);
  }

  void removeReaderListener(Function(int, int?) listener) {
    _readerListeners.remove(listener);
  }

  void addScreenListener(Function(int) listener) {
    _screenListeners.add(listener);
  }

  void removeScreenListener(Function(int) listener) {
    _screenListeners.remove(listener);
  }

  void navigateToReader(int bookId, [int? pageNum]) {
    print(
      'DEBUG: NavigationController.navigateToReader called with bookId=$bookId, pageNum=$pageNum',
    );
    try {
      for (final listener in _readerListeners) {
        listener(bookId, pageNum);
      }
    } catch (e, stackTrace) {
      print('ERROR: navigateToReader failed: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void navigateToScreen(int index) {
    print(
      'DEBUG: NavigationController.navigateToScreen called with index=$index',
    );
    try {
      for (final listener in _screenListeners) {
        listener(index);
      }
    } catch (e, stackTrace) {
      print('ERROR: navigateToScreen failed: $e');
      print('Stack trace: $stackTrace');
    }
  }
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);
    print(
      'DEBUG: App.build called, themeSettings.accentLabelColor: ${themeSettings.accentLabelColor}, themeType: ${themeSettings.themeType}',
    );

    // Determine theme based on ThemeSettings
    ThemeMode themeMode;
    switch (themeSettings.themeType) {
      case ThemeType.light:
        themeMode = ThemeMode.light;
        break;
      case ThemeType.dark:
        themeMode = ThemeMode.dark;
        break;
      case ThemeType.blackAndWhite:
        themeMode = ThemeMode.light;
        break;
    }

    return RestartWidget(
      child: MaterialApp(
        title: 'LuteForMobile',
        debugShowCheckedModeBanner: false,
        theme: switch (themeSettings.themeType) {
          ThemeType.blackAndWhite => AppTheme.blackAndWhiteTheme(themeSettings),
          _ => AppTheme.lightTheme(themeSettings),
        },
        darkTheme: AppTheme.darkTheme(themeSettings),
        themeMode: themeMode,
        home: const MainNavigation(),
      ),
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
  final GlobalKey<SentenceReaderScreenState> _sentenceReaderKey =
      GlobalKey<SentenceReaderScreenState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final NavigationController _navigationController;

  @override
  void initState() {
    super.initState();
    _navigationController = ref.read(navigationProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDrawerSettings();
      _loadLastReadBook();
    });
    _navigationController.addReaderListener(_handleNavigateToReader);
    _navigationController.addScreenListener(_handleNavigateToScreen);
  }

  @override
  void dispose() {
    _navigationController.removeReaderListener(_handleNavigateToReader);
    _navigationController.removeScreenListener(_handleNavigateToScreen);
    super.dispose();
  }

  void _handleNavigateToReader(int bookId, [int? pageNum]) {
    print(
      'DEBUG: _handleNavigateToReader called with bookId=$bookId, pageNum=$pageNum',
    );
    print('DEBUG: _readerKey.currentState=${_readerKey.currentState}');

    ref.read(settingsProvider.notifier).updateCurrentBook(bookId, pageNum);

    if (_readerKey.currentState != null) {
      _readerKey.currentState!.loadBook(bookId, pageNum);
    } else {
      print('ERROR: _readerKey.currentState is null!');
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

    final routeNames = [
      'reader',
      'books',
      'help',
      'settings',
      'sentence-reader',
    ];
    final currentRoute = routeNames[index];
    ref.read(currentScreenRouteProvider.notifier).setRoute(currentRoute);

    _updateDrawerSettings();
  }

  void _loadLastReadBook() async {
    final settings = ref.read(settingsProvider);
    if (settings.currentBookId != null) {
      print('DEBUG: Loading last read book: bookId=${settings.currentBookId}');

      try {
        final book = await ref
            .read(booksProvider.notifier)
            .getUpdatedBook(settings.currentBookId!);

        print(
          'DEBUG: Loaded book from server: bookId=${book.id}, currentPage=${book.currentPage}',
        );

        ref.read(settingsProvider.notifier).updateCurrentBook(book.id);

        if (_readerKey.currentState != null) {
          _readerKey.currentState!.loadBook(book.id);
        }
      } catch (e) {
        print('DEBUG: Failed to load book from server: $e');
        if (_readerKey.currentState != null) {
          _readerKey.currentState!.loadBook(settings.currentBookId!);
        }
      }
    }
  }

  void _updateDrawerSettings() {
    switch (_currentIndex) {
      case 0:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(ReaderDrawerSettings(currentIndex: _currentIndex));
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
      case 3:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(null);
        break;
      case 4:
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(ReaderDrawerSettings(currentIndex: _currentIndex));
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
        onNavigate: (index) async {
          setState(() {
            _currentIndex = index;
          });
          _updateDrawerSettings();
          if (index == 0 && _readerKey.currentState != null) {
            _readerKey.currentState!.reloadPage();
          }
          if (index == 1) {
            await ref.read(booksProvider.notifier).loadBooks();
          }
        },
      ),
      body: _currentIndex == 2
          ? const HelpScreen()
          : IndexedStack(
              index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
              children: [
                RepaintBoundary(
                  child: ReaderScreen(
                    key: _readerKey,
                    scaffoldKey: _scaffoldKey,
                  ),
                ),
                RepaintBoundary(child: BooksScreen(scaffoldKey: _scaffoldKey)),
                RepaintBoundary(
                  child: SettingsScreen(scaffoldKey: _scaffoldKey),
                ),
                RepaintBoundary(
                  child: SentenceReaderScreen(
                    key: _sentenceReaderKey,
                    scaffoldKey: _scaffoldKey,
                  ),
                ),
              ],
            ),
    );
  }
}
