import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/services/user_session_manager.dart';
import 'core/theme/app_colors.dart';
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
  bool _isMultitaskObscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPrivacyPreference();
  }

  Future<void> _initPrivacyPreference() async {
    try {
      if (sl.isRegistered<AppPreferencesDataSource>()) {
        final prefs = sl<AppPreferencesDataSource>();
        final enabled = await prefs.isPrivacyScreenEnabled();
        AppSessionNotifier.instance.setPrivacyScreenEnabled(enabled);
        final isPro = await prefs.getProStatus();
        final info = await prefs.getProSubscriptionInfo();
        final planTitle = switch (info['planId']) {
          'yearly' => 'Gói Năm',
          'monthly' => 'Gói Hàng Tháng',
          'lifetime' => 'Gói Trọn Đời',
          _ => null,
        };
        AppSessionNotifier.instance.setProStatus(isPro, planTitle: planTitle);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;

    final privacyEnabled = AppSessionNotifier.instance.privacyScreenEnabled;

    // Ẩn nội dung nhạy cảm trên trình chuyển đổi đa nhiệm (App Switcher)
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (privacyEnabled &&
          !_isMultitaskObscured &&
          !AppRoutes.isAppLockShowing &&
          !AppRoutes.isExternalPickerActive) {
        setState(() => _isMultitaskObscured = true);
      }
    }

    // Chỉ ghi nhận thời điểm khóa khi app thực sự vào background (paused).
    // Tuyệt đối KHÔNG bắt `inactive` hoặc khi đang mở Camera/Gallery hệ thống (`isExternalPickerActive`).
    if (state == AppLifecycleState.paused && !AppRoutes.isExternalPickerActive) {
      _lastBackgroundedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_isMultitaskObscured) {
        setState(() => _isMultitaskObscured = false);
      }
      if (!AppRoutes.isExternalPickerActive) {
        _checkAutoLock();
      }
    }
  }

  Future<void> _checkAutoLock() async {
    if (_lastBackgroundedTime == null || AppRoutes.isAppLockShowing) return;

    final backgroundTime = _lastBackgroundedTime;
    _lastBackgroundedTime = null;

    try {
      if (!sl.isRegistered<AppPreferencesDataSource>()) return;
      final prefs = sl<AppPreferencesDataSource>();
      final hasPin = await prefs.hasPin();
      final isBioEnabled = await prefs.isBiometricLockEnabled();
      final sessionUserId = await prefs.getSessionUserId();

      if ((hasPin || isBioEnabled) && sessionUserId != null && sessionUserId.isNotEmpty) {
        final timeout = await prefs.getAutoLockTimeout(); // 0: immediate, 1: 1 minute
        final elapsedSeconds = DateTime.now().difference(backgroundTime!).inSeconds;

        if (timeout == 0 || elapsedSeconds >= (timeout * 60)) {
          final nav = SoTayYTeApp.navigatorKey.currentState;
          if (nav != null && !AppRoutes.isAppLockShowing) {
            AppRoutes.isAppLockShowing = true;
            nav.pushNamed(
              AppRoutes.appLock,
              arguments: () {
                AppRoutes.isAppLockShowing = false;
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
      builder: (context, child) {
        return Stack(
          children: [
            ?child,
            if (_isMultitaskObscured)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    color: AppColors.secBackground.withValues(alpha: 0.92),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 52,
                          color: AppColors.iceOlive,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Sổ Tay Y Tế',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceTextNavy,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Nội dung y tế đang được che bảo vệ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.iceTextSlate,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
