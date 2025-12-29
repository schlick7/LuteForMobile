import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lute_for_mobile/features/reader/widgets/reader_screen.dart';
import 'package:lute_for_mobile/features/settings/widgets/settings_screen.dart';
import 'package:lute_for_mobile/shared/theme/app_theme.dart';
import 'package:lute_for_mobile/features/settings/providers/settings_provider.dart';
import 'package:lute_for_mobile/shared/widgets/app_drawer.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0 && _readerKey.currentState != null) {
            _readerKey.currentState!.reloadPage();
          }
        },
        isSettingsView: _currentIndex == 1,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ReaderScreen(key: _readerKey, scaffoldKey: _scaffoldKey),
          SettingsScreen(scaffoldKey: _scaffoldKey),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0 && _readerKey.currentState != null) {
            _readerKey.currentState!.reloadPage();
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book), label: 'Reader'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
