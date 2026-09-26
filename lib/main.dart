import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/apps_provider.dart';
import 'providers/session_provider.dart';
import 'screens/apps_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/timer_screen.dart';
import 'services/app_preferences_service.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';

/// Entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  await AppPreferencesService.instance.init();
  runApp(const FocusGuardApp());
}

class FocusGuardApp extends StatelessWidget {
  const FocusGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppsProvider()),
        ChangeNotifierProvider(
          create: (_) => SessionProvider()..restoreActiveSessionIfAny(),
        ),
      ],
      child: MaterialApp(
        title: 'FocusGuard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const _RootRouter(),
      ),
    );
  }
}

/// Decides between onboarding and the main app shell based on whether
/// onboarding has already completed. Re-checked via setState after
/// onboarding finishes rather than at app-restart, so the user drops
/// straight into the app the moment they're done.
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _onboardingCompleted =
      AppPreferencesService.instance.isOnboardingCompleted;

  @override
  Widget build(BuildContext context) {
    if (!_onboardingCompleted) {
      return OnboardingScreen(
        onComplete: () => setState(() => _onboardingCompleted = true),
      );
    }
    return const MainAppShell();
  }
}

/// Main application shell with bottom navigation for all core sections.
class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> with WidgetsBindingObserver {
  int _selectedIndex = 2; // Start with Home (now at index 2)

  static const List<Widget> _screens = <Widget>[
    AppsScreen(),
    HistoryScreen(),
    HomeScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Installed apps can change while FocusGuard is backgrounded
      // (install/uninstall). Refresh so the Apps tab doesn't need a manual
      // navigate-away-and-back to pick that up.
      context.read<AppsProvider>().loadApps();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _screens[_selectedIndex]),
          const _ActiveSessionReturnBar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_outlined),
            activeIcon: Icon(Icons.apps),
            label: 'Apps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}

/// Persistent, always-on-top-of-the-tabs bar that appears whenever a focus
/// session is running or paused, no matter which tab you're on, and jumps
/// straight back into it. Previously the only way back to an in-progress
/// session was to trigger the "Start Focus Session" entry point again
/// (which happened to show the active session instead of the setup form,
/// but nothing signaled that) - there was no visible, obvious way to
/// return to a session in progress.
class _ActiveSessionReturnBar extends StatelessWidget {
  const _ActiveSessionReturnBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        if (!provider.hasActiveSession) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;
        final label = provider.isPaused
            ? 'Session paused - tap to resume'
            : '${provider.phaseLabel} in progress - tap to return';

        return Material(
          color: colorScheme.primary,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimerScreen()),
              );
            },
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      provider.isPaused ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}