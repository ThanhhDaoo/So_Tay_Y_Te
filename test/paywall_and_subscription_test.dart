import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:so_tay_y_te/core/di/injection_container.dart';
import 'package:so_tay_y_te/data/datasources/local/app_preferences_datasource.dart';
import 'package:so_tay_y_te/data/datasources/remote/subscription_remote_datasource.dart';
import 'package:so_tay_y_te/presentation/features/paywall/view/paywall_screen.dart';
import 'package:so_tay_y_te/presentation/features/paywall/view/widgets/vault_pro_payment_sheet.dart';
import 'package:so_tay_y_te/presentation/features/paywall/viewmodel/paywall_state.dart';
import 'package:so_tay_y_te/presentation/features/paywall/viewmodel/paywall_viewmodel.dart';

class MockSubscriptionRemoteDataSource implements SubscriptionRemoteDataSource {
  bool purchaseCalled = false;
  bool restoreCalled = false;
  bool succeed = true;

  @override
  Future<bool> purchaseProSubscription(String packageId) async {
    purchaseCalled = true;
    return succeed;
  }

  @override
  Future<bool> restorePurchases() async {
    restoreCalled = true;
    return succeed;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferencesDataSource preferencesDataSource;
  late MockSubscriptionRemoteDataSource mockSubscription;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();

    preferencesDataSource = AppPreferencesDataSourceImpl();
    mockSubscription = MockSubscriptionRemoteDataSource();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Phase 4: In-App Purchase & Paywall ViewModel Tests', () {
    test('selectPlan switches between Yearly, Monthly, and Lifetime plans', () {
      final vm = PaywallViewModel(
        subscriptionDataSource: mockSubscription,
        preferencesDataSource: preferencesDataSource,
      );

      expect(vm.state.selectedPlan, equals(PlanType.yearly));

      vm.selectPlan(PlanType.monthly);
      expect(vm.state.selectedPlan, equals(PlanType.monthly));

      vm.selectPlan(PlanType.lifetime);
      expect(vm.state.selectedPlan, equals(PlanType.lifetime));
    });

    test('subscribeToPlan purchases package and permanently unlocks Pro in preferences', () async {
      final vm = PaywallViewModel(
        subscriptionDataSource: mockSubscription,
        preferencesDataSource: preferencesDataSource,
      );

      expect(await preferencesDataSource.getProStatus(), isFalse);
      expect(vm.state.isPro, isFalse);

      final result = await vm.subscribeToPlan(PlanType.yearly);

      expect(result, isTrue);
      expect(mockSubscription.purchaseCalled, isTrue);
      expect(vm.state.isPro, isTrue);
      expect(await preferencesDataSource.getProStatus(), isTrue);
      expect(vm.state.feedbackMessage, contains('Kích hoạt thành công'));
    });

    test('restorePurchases recovers existing Pro license and updates status', () async {
      final vm = PaywallViewModel(
        subscriptionDataSource: mockSubscription,
        preferencesDataSource: preferencesDataSource,
      );

      final result = await vm.restorePurchases();

      expect(result, isTrue);
      expect(mockSubscription.restoreCalled, isTrue);
      expect(vm.state.isPro, isTrue);
      expect(await preferencesDataSource.getProStatus(), isTrue);
      expect(vm.state.feedbackMessage, contains('Đã khôi phục thành công'));
    });

    test('linkAccount links user identity providers smoothly', () async {
      final vm = PaywallViewModel(
        subscriptionDataSource: mockSubscription,
        preferencesDataSource: preferencesDataSource,
      );

      await vm.linkAccount('Google');
      expect(vm.state.linkedProvider, equals('Google'));
      expect(vm.state.feedbackMessage, contains('Google'));
    });
  });

  group('Phase 4: PaywallScreen & VaultProPaymentSheet Widget Tests', () {
    testWidgets('PaywallScreen renders pricing selector and features checklist', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gói Vault Pro'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Gói Năm'), 200);
      expect(find.text('Gói Năm'), findsOneWidget);
      expect(find.text('Gói Hàng Tháng'), findsOneWidget);
      expect(find.text('Gói Trọn Đời'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Khôi phục giao dịch mua trước đây'), 200);
      expect(find.text('Khôi phục giao dịch mua trước đây'), findsOneWidget);
    });

    testWidgets('VaultProPaymentSheet confirms payment and activates Pro badge', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool completed = false;
      final vm = PaywallViewModel(
        subscriptionDataSource: mockSubscription,
        preferencesDataSource: preferencesDataSource,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  VaultProPaymentSheet.show(
                    ctx,
                    selectedPlan: PlanType.yearly,
                    viewModel: vm,
                    onSuccess: () => completed = true,
                  );
                },
                child: const Text('Open Payment'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open payment sheet
      await tester.tap(find.text('Open Payment'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Xác Nhận Đăng Ký'), findsOneWidget);
      expect(find.textContaining('Dùng Thử 7 Ngày'), findsOneWidget);

      // Confirm payment
      await tester.tap(find.textContaining('Dùng Thử 7 Ngày'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(vm.state.isPro, isTrue);
      expect(await preferencesDataSource.getProStatus(), isTrue);
    });

    testWidgets('Full simulated flow transitions PaywallScreen to VaultProActiveDashboard and supports reset', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      sl.registerSingleton<AppPreferencesDataSource>(preferencesDataSource);
      sl.registerSingleton<SubscriptionRemoteDataSource>(mockSubscription);

      await tester.pumpWidget(
        const MaterialApp(
          home: PaywallScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Free state initially
      expect(find.text('Nâng Cấp Sổ Tay Y Tế Pro'), findsOneWidget);

      // Tap CTA to open simulated payment sheet
      final ctaFinder = find.textContaining('Dùng thử 7 ngày miễn phí');
      await tester.scrollUntilVisible(
        ctaFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(ctaFinder);
      await tester.pumpAndSettle();
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();

      // Switch to VietQR method and verify QR preview renders
      final vietQrFinder = find.textContaining('VietQR');
      await tester.ensureVisible(vietQrFinder);
      await tester.tap(vietQrFinder);
      await tester.pumpAndSettle();
      expect(find.text('Mã VietQR Giả Lập'), findsOneWidget);

      // Confirm payment -> transitions to Vault Pro Active Dashboard
      await tester.tap(find.textContaining('Dùng Thử 7 Ngày'));
      await tester.pumpAndSettle();

      expect(find.text('VAULT PRO • ĐANG HOẠT ĐỘNG'), findsOneWidget);
      expect(find.text('5 Đặc Quyền Đã Mở Khóa'), findsOneWidget);

      // Clear congratulatory floating snackbar before tapping bottom button
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pumpAndSettle();

      // Reset back to Free for re-testing
      final resetFinder = find.text('Reset về Free');
      await tester.scrollUntilVisible(
        resetFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(resetFinder);
      await tester.pumpAndSettle();
      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset về Free'));
      await tester.pumpAndSettle();

      expect(find.text('Nâng Cấp Sổ Tay Y Tế Pro'), findsOneWidget);
      expect(await preferencesDataSource.getProStatus(), isFalse);
    });
  });
}
