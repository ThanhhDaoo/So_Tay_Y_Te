import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/security/biometric_service.dart';
import 'package:so_tay_y_te/data/datasources/local/app_preferences_datasource.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/view/app_lock_screen.dart';
import 'package:so_tay_y_te/presentation/features/security_settings/viewmodel/security_settings_viewmodel.dart';
import 'package:so_tay_y_te/presentation/routes/app_routes.dart';

class MockSuccessBiometricService implements BiometricService {
  @override
  Future<bool> isBiometricAvailable() async => true;

  @override
  Future<List<BiometricHardwareType>> getAvailableBiometrics() async => [BiometricHardwareType.face];

  @override
  Future<bool> authenticate({required String localizedReason}) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sub-module 2.4: AppLockScreen Widget Tests', () {
    late AppPreferencesDataSource prefsDs;
    late SecuritySettingsViewModel viewModel;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefsDs = AppPreferencesDataSourceImpl();
      viewModel = SecuritySettingsViewModel(
        preferencesDataSource: prefsDs,
        biometricService: MockSuccessBiometricService(),
      );
      // Save test PIN '123456'
      await viewModel.saveNewPin('123456');
    });

    testWidgets('Renders all security keypad elements and emergency ICE shortcut', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.emergencyCard: (_) => const Scaffold(body: Text('ICE Card Screen')),
          },
          home: AppLockScreen(
            onUnlocked: () {},
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sổ Tay Y Tế'), findsOneWidget);
      expect(find.text('Hồ sơ sức khỏe đang được khóa bảo vệ'), findsOneWidget);
      expect(find.text('Mở Thẻ Cấp Cứu Khẩn Cấp (ICE)'), findsOneWidget);

      // Verify digits 0-9
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Tap Emergency button to verify medical access without PIN
      await tester.tap(find.text('Mở Thẻ Cấp Cứu Khẩn Cấp (ICE)'));
      await tester.pumpAndSettle();
      expect(find.text('ICE Card Screen'), findsOneWidget);
    });

    testWidgets('Entering correct 6-digit PIN calls onUnlocked callback', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool unlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppLockScreen(
            onUnlocked: () => unlocked = true,
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter PIN '123456'
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pump();
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
    });

    testWidgets('Entering incorrect PIN shows error message', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool unlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppLockScreen(
            onUnlocked: () => unlocked = true,
            viewModel: viewModel,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter wrong PIN '999999'
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('9'));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(unlocked, isFalse);
      expect(find.text('Mã PIN không chính xác. Vui lòng thử lại!'), findsOneWidget);
    });
  });
}
