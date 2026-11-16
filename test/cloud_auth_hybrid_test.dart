import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/core/config/firebase_config.dart';
import 'package:so_tay_y_te/core/config/supabase_config.dart';
import 'package:so_tay_y_te/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:so_tay_y_te/presentation/features/auth/view/widgets/cloud_backend_status_badge.dart';
import 'package:so_tay_y_te/presentation/features/auth/view/widgets/phone_otp_bottom_sheet.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/login_state.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/login_viewmodel.dart';
import 'social_auth_linking_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cloud Auth (Supabase & Firebase Hybrid) Tests', () {
    test('FirebaseConfig & SupabaseConfig initialize cleanly in sandbox mode', () async {
      await FirebaseConfig.initialize();
      await SupabaseConfig.initialize();

      expect(FirebaseConfig.isInitialized, isTrue);
      // In default test environment without real secrets, isConfigured should be false (safe fallback)
      expect(FirebaseConfig.isConfigured, isFalse);
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('FirebaseAuthRemoteDataSource handles Vietnam phone normalization & OTP', () async {
      final ds = FirebaseAuthRemoteDataSourceImpl();

      // Normalizes 0912345678 to +84912345678
      final verId = await ds.sendPhoneOtp('0912345678');
      expect(verId, startsWith('fb-ver-'));

      // Rejects invalid phone numbers
      expect(() => ds.sendPhoneOtp('123'), throwsException);

      // Verifies using universal test OTP 123456
      final account = await ds.verifyPhoneOtp(
        phoneNumber: '0912345678',
        verificationId: verId,
        smsCode: '123456',
      );

      expect(account.primaryContact, equals('+84912345678'));
      expect(account.patientCode, startsWith('STYT-'));
      expect(account.id, startsWith('fb-uid-'));

      // Rejects wrong OTP
      final verId2 = await ds.sendPhoneOtp('0988776655');
      expect(
        () => ds.verifyPhoneOtp(
          phoneNumber: '0988776655',
          verificationId: verId2,
          smsCode: '000000',
        ),
        throwsException,
      );
    });

    test('LoginViewModel triggers sendPhoneOtp and verifyPhoneOtp smoothly', () async {
      final mockRepo = MockSocialAuthRepository();
      final vm = LoginViewModel(authRepository: mockRepo);

      final verId = await vm.sendPhoneOtp('0912345678');
      expect(verId, isNotEmpty);

      final ok = await vm.verifyPhoneOtp(
        phoneNumber: '0912345678',
        verificationId: verId,
        smsCode: '123456',
      );

      expect(ok, isTrue);
      expect(vm.state.status, equals(LoginStatus.success));
      expect(vm.state.loggedInUser, isNotNull);
      expect(vm.state.loggedInUser!.patientCode, startsWith('STYT-'));
    });

    testWidgets('CloudBackendStatusBadge renders and opens dialog on tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CloudBackendStatusBadge(),
            ),
          ),
        ),
      );

      expect(find.byType(CloudBackendStatusBadge), findsOneWidget);
      expect(find.text('Local-First + Cloud Ready'), findsOneWidget);

      await tester.tap(find.byType(CloudBackendStatusBadge));
      await tester.pumpAndSettle();

      expect(find.text('Kiến Trúc Đám Mây'), findsOneWidget);
      expect(find.text('Supabase PostgreSQL'), findsOneWidget);
      expect(find.text('Firebase Auth Engine'), findsOneWidget);
      expect(find.text('Local-First SQLite Vault'), findsOneWidget);

      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();

      expect(find.text('Kiến Trúc Đám Mây'), findsNothing);
    });

    testWidgets('PhoneOtpBottomSheet shows input and advances to 6-digit OTP step', (tester) async {
      final mockRepo = MockSocialAuthRepository();
      final vm = LoginViewModel(authRepository: mockRepo);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PhoneOtpBottomSheet.show(
                    context: ctx,
                    viewModel: vm,
                    onSuccess: (_) {},
                  );
                },
                child: const Text('Open OTP'),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Open OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Đăng Nhập Số Điện Thoại'), findsOneWidget);
      expect(find.text('Gửi Mã Xác Thực (SMS OTP)'), findsOneWidget);

      // Tap Send OTP
      await tester.tap(find.text('Gửi Mã Xác Thực (SMS OTP)'));
      await tester.pumpAndSettle();

      expect(find.text('Xác Thực Mã OTP'), findsOneWidget);
      expect(find.text('Điền mã test: 123456'), findsOneWidget);
    });
  });
}
