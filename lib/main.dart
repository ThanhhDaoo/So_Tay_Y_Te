import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local/app_preferences_datasource.dart';
import 'presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Dependency Injection và Local Storage/DB
  await InjectionContainer.init();

  runApp(const SoTayYTeApp());
}

class SoTayYTeApp extends StatefulWidget {
  const SoTayYTeApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<SoTayYTeApp> createState() => _SoTayYTeAppState();
}

class _SoTayYTeAppState extends State<SoTayYTeApp> with WidgetsBindingObserver {
  DateTime? _lastBackgroundedTime;
  bool _isAppLockOpen = false;

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
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lastBackgroundedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    }
  }

  Future<void> _checkAutoLock() async {
    if (_lastBackgroundedTime == null || _isAppLockOpen) return;

    try {
      if (!sl.isRegistered<AppPreferencesDataSource>()) return;
      final prefs = sl<AppPreferencesDataSource>();
      final hasPin = await prefs.hasPin();
      final isBioEnabled = await prefs.isBiometricLockEnabled();
      final sessionUserId = await prefs.getSessionUserId();

      if ((hasPin || isBioEnabled) && sessionUserId != null && sessionUserId.isNotEmpty) {
        final timeout = await prefs.getAutoLockTimeout(); // 0: immediate, 1: 1 minute
        final elapsedSeconds = DateTime.now().difference(_lastBackgroundedTime!).inSeconds;

        if (timeout == 0 || elapsedSeconds >= 60) {
          final nav = SoTayYTeApp.navigatorKey.currentState;
          if (nav != null) {
            _isAppLockOpen = true;
            nav.pushNamed(
              AppRoutes.appLock,
              arguments: () {
                _isAppLockOpen = false;
                _lastBackgroundedTime = null;
              },
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SoTayYTeApp.navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: const Locale('vi', 'VN'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      initialRoute: AppRoutes.login,
      onGenerateInitialRoutes: (initialRoute) => [
        AppRoutes.onGenerateRoute(RouteSettings(name: initialRoute)),
      ],
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
