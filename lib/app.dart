import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/core/logger/api_logger.dart';
import 'package:lute_for_mobile/features/reader/widgets/reader_screen.dart';
import 'package:lute_for_mobile/features/reader/widgets/reader_drawer_settings.dart';
import 'package:lute_for_mobile/features/reader/widgets/sentence_reader_screen.dart';
import 'package:lute_for_mobile/features/reader/providers/current_book_provider.dart';

import 'package:lute_for_mobile/features/settings/widgets/settings_screen.dart';
import 'package:lute_for_mobile/features/settings/widgets/help_screen.dart';
import 'package:lute_for_mobile/features/books/widgets/books_screen.dart';
import 'package:lute_for_mobile/features/books/widgets/books_drawer_settings.dart';
import 'package:lute_for_mobile/features/terms/widgets/terms_screen.dart';
import 'package:lute_for_mobile/features/stats/widgets/stats_screen.dart';
import 'package:lute_for_mobile/shared/theme/app_theme.dart';
import 'package:lute_for_mobile/shared/theme/theme_definitions.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/features/settings/models/settings.dart';
import 'package:lute_for_mobile/shared/widgets/app_drawer.dart';
import 'package:lute_for_mobile/features/books/providers/books_provider.dart';
import 'package:lute_for_mobile/features/books/models/book.dart';
import 'package:lute_for_mobile/core/services/termux_service.dart';
import 'package:lute_for_mobile/core/services/server_health_service.dart';
import 'package:lute_for_mobile/shared/providers/server_status_provider.dart';
import 'package:lute_for_mobile/shared/providers/app_startup_providers.dart';
import 'package:lute_for_mobile/core/network/api_service.dart';

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
  final List<Function(String)> _screenListeners = [];

  void addReaderListener(Function(int, int?) listener) {
    _readerListeners.add(listener);
  }

  void removeReaderListener(Function(int, int?) listener) {
    _readerListeners.remove(listener);
  }

  void addScreenListener(Function(String) listener) {
    _screenListeners.add(listener);
  }

  void removeScreenListener(Function(String) listener) {
    _screenListeners.remove(listener);
  }

  void navigateToReader(int bookId, [int? pageNum]) {
    ApiLogger.logRequest(
      'NavigationController.navigateToReader',
      details: 'bookId=$bookId, pageNum=$pageNum',
    );
    try {
      for (final listener in _readerListeners) {
        listener(bookId, pageNum);
      }
      navigateToScreen('reader');
    } catch (e, stackTrace) {
      ApiLogger.logError('navigateToReader', e, stackTrace: stackTrace);
    }
  }

  void navigateToScreen(String route) {
    try {
      for (final listener in _screenListeners) {
        listener(route);
      }
    } catch (e, stackTrace) {
      ApiLogger.logError(
        'NavigationController.navigateToScreen',
        e,
        stackTrace: stackTrace,
      );
    }
  }
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeSettingsProvider);

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
  final GlobalKey<State<StatefulWidget>> _booksKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _statsKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _settingsKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<SentenceReaderScreenState> _sentenceReaderKey =
      GlobalKey<SentenceReaderScreenState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final NavigationController _navigationController;
  final GlobalKey<State<StatefulWidget>> _termsKey =
      GlobalKey<State<StatefulWidget>>();
  final GlobalKey<State<StatefulWidget>> _helpKey =
      GlobalKey<State<StatefulWidget>>();
  bool _needsDataRefresh = false;

  @override
  void initState() {
    super.initState();
    _navigationController = ref.read(navigationProvider);

    // Reset route to 'reader' on initialization to handle app restart
    // When RestartWidget.restartApp() is called, providers persist but widgets rebuild,
    // so we need to ensure the route matches the initial tab (_currentIndex = 0)
    ref.read(currentScreenRouteProvider.notifier).setRoute('reader');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDrawerSettings();
      _checkServerHealth();
      _checkAndStartLute3IfNeeded();
      _loadLastReadBook();
    });
    _navigationController.addReaderListener(_handleNavigateToReader);
    _navigationController.addScreenListener(_handleNavigateToScreen);
  }

  Future<void> _checkServerHealth() async {
    final settings = ref.read(settingsProvider);
    if (settings.serverUrl.isEmpty) return;

    ApiLogger.logRequest('ServerHealthCheck');
    final isReachable = await ServerHealthService.isReachable(
      settings.serverUrl,
    );
    ServerStatusManager.setReachable(isReachable);
  }

  Future<void> _checkAndStartLute3IfNeeded() async {
    final settings = ref.read(settingsProvider);
    if (settings.serverUrl == Settings.termuxUrl &&
        settings.termuxAutoLaunchEnabled) {
      for (int i = 0; i < 15; i++) {
        final isRunning = await TermuxService.isServerRunning(
          settings.serverUrl,
        );
        if (isRunning) {
          if (_needsDataRefresh) {
            _needsDataRefresh = false;
            ref.read(booksProvider.notifier).loadBooks(forceRefresh: true);
            _loadLastReadBook();
          }
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  @override
  void dispose() {
    _navigationController.removeReaderListener(_handleNavigateToReader);
    _navigationController.removeScreenListener(_handleNavigateToScreen);
    super.dispose();
  }

  void _handleNavigateToReader(int bookId, [int? pageNum]) {
    final booksState = ref.read(booksProvider);
    final allBooks = [...booksState.activeBooks, ...booksState.archivedBooks];
    final book = allBooks.firstWhere(
      (b) => b.id == bookId,
      orElse: () => Book(
        id: bookId,
        title: '',
        language: '',
        langId: 0,
        totalPages: 0,
        currentPage: 0,
        percent: 0,
        wordCount: 0,
        distinctTerms: null,
        unknownPct: null,
        statusDistribution: null,
        lastStatsRefresh: null,
      ),
    );

    ref
        .read(settingsProvider.notifier)
        .updateCurrentBook(bookId, pageNum, book.langId);

    ref.read(currentBookProvider.notifier).setBook(book);
    ref.read(booksProvider.notifier).setCurrentBook(bookId);

    setState(() {
      _currentIndex = 0;
    });

    if (_readerKey.currentState != null) {
      _readerKey.currentState!.loadBook(bookId, pageNum);
    } else {
      ApiLogger.logError(
        '_handleNavigateToReader',
        Exception('Reader not ready'),
      );
    }
    _updateDrawerSettings();
  }

  void _handleNavigateToScreen(String route) {
    final routeToIndex = {
      'reader': 0,
      'books': 1,
      'terms': 2,
      'stats': 3,
      'help': 4,
      'settings': 5,
      'sentence-reader': 6,
    };

    final index = routeToIndex[route] ?? 0;
    setState(() {
      _currentIndex = index;
    });

    if (route == 'books') {
      ref.read(booksProvider.notifier).loadBooks();
    }

    ref.read(currentScreenRouteProvider.notifier).setRoute(route);
    _updateDrawerSettings();
  }

  void _loadLastReadBook() async {
    final settings = ref.read(settingsProvider);
    if (settings.currentBookId == null) return;

    if (_readerKey.currentState != null) {
      await _readerKey.currentState!.loadBook(settings.currentBookId!);
    }
  }

  void _updateDrawerSettings() {
    final currentRoute = ref.read(currentScreenRouteProvider);
    switch (currentRoute) {
      case 'reader':
      case 'settings':
      case 'sentence-reader':
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(ReaderDrawerSettings(currentRoute: currentRoute));
        break;
      case 'books':
        ref
            .read(currentViewDrawerSettingsProvider.notifier)
            .updateSettings(const BooksDrawerSettings());
        break;
      case 'terms':
      case 'stats':
      case 'help':
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
    // Watch for books loading completion and trigger auto backup
    ref.listen(booksLoadingCompleteProvider, (previous, next) {
      if (next == true && previous != true) {
        final settings = ref.read(settingsProvider);
        if (settings.serverUrl.isNotEmpty) {
          final apiService = ApiService(baseUrl: settings.serverUrl);
          apiService.triggerAutoBackup();
        }
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentRoute: ref.watch(currentScreenRouteProvider),
        onNavigate: (route) async {
          _handleNavigateToScreen(route);
          if (route == 'reader' && _readerKey.currentState != null) {
            _readerKey.currentState!.reloadPage();
          }
        },
      ),
      body: _currentIndex == 4
          ? HelpScreen(key: _helpKey, scaffoldKey: _scaffoldKey)
          : _currentIndex == 6
          ? SentenceReaderScreen(
              key: _sentenceReaderKey,
              scaffoldKey: _scaffoldKey,
            )
          : IndexedStack(
              index: _currentIndex > 4 ? _currentIndex - 1 : _currentIndex,
              children: [
                Consumer(
                  builder: (context, ref, child) =>
                      ReaderScreen(key: _readerKey, scaffoldKey: _scaffoldKey),
                ),
                Consumer(
                  builder: (context, ref, child) =>
                      BooksScreen(key: _booksKey, scaffoldKey: _scaffoldKey),
                ),
                Consumer(
                  builder: (context, ref, child) =>
                      TermsScreen(key: _termsKey, scaffoldKey: _scaffoldKey),
                ),
                Consumer(
                  builder: (context, ref, child) =>
                      StatsScreen(key: _statsKey, scaffoldKey: _scaffoldKey),
                ),
                Consumer(
                  builder: (context, ref, child) => SettingsScreen(
                    key: _settingsKey,
                    scaffoldKey: _scaffoldKey,
                  ),
                ),
              ],
            ),
    );
  }
}
