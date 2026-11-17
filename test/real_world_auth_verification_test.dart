import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/core/utils/input_validators.dart';
import 'package:so_tay_y_te/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:so_tay_y_te/presentation/features/auth/view/widgets/forgot_password_bottom_sheet.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/login_state.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/login_viewmodel.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/register_state.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/register_viewmodel.dart';

import 'login_flow_test.dart';
import 'register_flow_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real-World Auth & Identity Verification Suite', () {
    test('InputValidators classifies and normalizes VN phones, emails, and STYT codes accurately', () {
      expect(
        InputValidators.classifyIdentifier('0912 345 678'),
        equals(AuthIdentifierType.phone),
      );
      expect(
        InputValidators.classifyIdentifier('+84 362-625-218'),
        equals(AuthIdentifierType.phone),
      );
      expect(
        InputValidators.classifyIdentifier('912345678'),
        equals(AuthIdentifierType.phone),
      );
      expect(
        InputValidators.classifyIdentifier('STYT-482910'),
        equals(AuthIdentifierType.patientCode),
      );
      expect(
        InputValidators.classifyIdentifier('bacsi.an@benhvien.vn'),
        equals(AuthIdentifierType.email),
      );
      expect(
        InputValidators.classifyIdentifier('abc-invalid'),
        equals(AuthIdentifierType.unknown),
      );
      expect(
        InputValidators.classifyIdentifier('0111222333'),
        equals(AuthIdentifierType.unknown),
      );

      expect(
        InputValidators.normalizePhoneLocal('+84 912 345 678'),
        equals('0912345678'),
      );
      expect(
        InputValidators.normalizePhoneE164('0912.345.678'),
        equals('+84912345678'),
      );
      expect(
        InputValidators.maskContact('0912345678'),
        equals('091***678'),
      );
      expect(
        InputValidators.maskContact('thanhdao@gmail.com'),
        equals('tha***@gmail.com'),
      );
    });

    test('Registration blocks duplicate phone/email BEFORE sending OTP', () async {
      final mockRepo = MockTestAuthRepository();
      final vm1 = RegisterViewModel(authRepository: mockRepo);

      vm1.toggleAcceptedTerms(true);
      vm1.fullNameController.text = 'Nguyễn Văn An';
      vm1.contactController.text = '0912345678';
      vm1.passwordController.text = 'MatKhau@123';
      vm1.confirmPasswordController.text = 'MatKhau@123';

      // Đăng ký lần 1 qua luồng chuẩn: yêu cầu SMS OTP vì là SĐT mới
      final step1 = await vm1.initiateRegistrationFlow();
      expect(step1, equals(RegistrationFlowStep.requirePhoneOtp));
      final otpOk = await vm1.verifyOtpAndRegister('123456');
      expect(otpOk, isTrue);

      // Đăng ký lần 2 trùng SĐT: phát hiện ngay trước khi gửi OTP
      final vm2 = RegisterViewModel(authRepository: mockRepo);
      vm2.toggleAcceptedTerms(true);
      vm2.fullNameController.text = 'Trần Thị Bình';
      vm2.contactController.text = '0912345678';
      vm2.passwordController.text = 'MatKhau@456';
      vm2.confirmPasswordController.text = 'MatKhau@456';

      final step2 = await vm2.initiateRegistrationFlow();
      expect(step2, equals(RegistrationFlowStep.failed));
      expect(vm2.state.errorMessage, contains('đã được đăng ký'));
    });

    test('Dynamic OTP is one-time-use and bound to the requesting phone number', () async {
      final ds = FirebaseAuthRemoteDataSourceImpl();
      final verId = await ds.sendPhoneOtp('0912345678');
      final dynamicCode = ds.peekSandboxOtp(verId);
      expect(dynamicCode, isNotNull);
      expect(dynamicCode!.length, equals(6));

      // Không cho phép dùng OTP của số A để xác thực số B
      expect(
        () => ds.verifyPhoneOtp(
          phoneNumber: '0988776655',
          verificationId: verId,
          smsCode: dynamicCode,
        ),
        throwsException,
      );

      // Xác thực đúng số A + mã động thành công
      final account = await ds.verifyPhoneOtp(
        phoneNumber: '0912345678',
        verificationId: verId,
        smsCode: dynamicCode,
      );
      expect(account.primaryContact, equals('+84912345678'));

      // Sau khi dùng xong, peekSandboxOtp đã bị hủy (one-time password)
      expect(ds.peekSandboxOtp(verId), isNull);
    });

    test('Biometric login works seamlessly AFTER user logs out via bound account', () async {
      final mockRepo = MockLoginAuthRepository();
      final bioService = MockSuccessBiometricService();
      final vm = LoginViewModel(
        authRepository: mockRepo,
        biometricService: bioService,
      );

      // 1. Đăng nhập lần đầu bằng mật khẩu -> hệ thống tự liên kết tài khoản sinh trắc học
      vm.identifierController.text = 'STYT-892410';
      vm.passwordController.text = '123456';
      expect(await vm.signInWithEmailOrId(), isTrue);

      // 2. Đăng xuất (xóa activeSession, các ô nhập trống như mở app mới)
      await mockRepo.logout();
      expect(await mockRepo.getActiveSession(), isNull);

      final freshVmAfterLogout = LoginViewModel(
        authRepository: mockRepo,
        biometricService: bioService,
      );
      expect(freshVmAfterLogout.identifierController.text, isEmpty);
      expect(freshVmAfterLogout.passwordController.text, isEmpty);

      // 3. Nhấn nút Face ID -> đăng nhập thành công nhờ tài khoản đã liên kết trên thiết bị
      final bioOk = await freshVmAfterLogout.signInWithBiometrics();
      expect(bioOk, isTrue);
      expect(freshVmAfterLogout.state.status, equals(LoginStatus.success));
      expect(
        freshVmAfterLogout.state.loggedInUser?.patientCode,
        equals('STYT-892410'),
      );
    });

    test('3-step Identity-Verified Password Recovery rejects wrong OTP and resets on valid OTP', () async {
      final mockRepo = MockLoginAuthRepository();
      final vm = LoginViewModel(authRepository: mockRepo);

      final challenge =
          await vm.sendPasswordRecoveryChallenge('STYT-892410');
      expect(challenge.maskedContact, contains('***'));

      // Sai mã OTP -> từ chối đổi mật khẩu
      final wrongOtpOk = await vm.verifyRecoveryAndResetPassword(
        identifier: 'STYT-892410',
        verificationId: challenge.verificationId,
        otpCode: '000000',
        newPassword: 'NewSecurePassword99!',
      );
      expect(wrongOtpOk, isFalse);

      // Đúng mã OTP -> đổi mật khẩu thành công
      final validOtpOk = await vm.verifyRecoveryAndResetPassword(
        identifier: 'STYT-892410',
        verificationId: challenge.verificationId,
        otpCode: challenge.sandboxOtpPreview!,
        newPassword: 'NewSecurePassword99!',
      );
      expect(validOtpOk, isTrue);

      // Đăng nhập bằng mật khẩu mới thành công
      vm.identifierController.text = 'STYT-892410';
      vm.passwordController.text = 'NewSecurePassword99!';
      expect(await vm.signInWithEmailOrId(), isTrue);
    });

    testWidgets('ForgotPasswordBottomSheet walks through 3-step identity verification smoothly', (tester) async {
      final mockRepo = MockLoginAuthRepository();
      final vm = LoginViewModel(authRepository: mockRepo);
      String? recoveredId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  ForgotPasswordBottomSheet.show(
                    context: ctx,
                    viewModel: vm,
                    onPasswordResetSuccess: (id) => recoveredId = id,
                  );
                },
                child: const Text('Quên mật khẩu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Quên mật khẩu'));
      await tester.pumpAndSettle();

      // Bước 1: Nhập Mã hồ sơ
      expect(find.text('Khôi Phục Mật Khẩu'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'STYT-892410');
      await tester.tap(find.text('Gửi Mã Xác Minh Danh Tính'));
      await tester.pumpAndSettle();

      // Bước 2: Xác minh danh tính 6 số (nhấn Tự động điền từ SMS Sandbox)
      expect(find.text('Xác Minh Danh Tính'), findsWidgets);
      await tester.tap(find.text('Tự động điền'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Xác Minh Danh Tính'));
      await tester.pumpAndSettle();

      // Bước 3: Thiết lập mật khẩu mới
      expect(find.text('Thiết Lập Mật Khẩu Mới'), findsOneWidget);
      final passFields = find.byType(TextField);
      await tester.enterText(passFields.at(0), 'MatKhauMoi2026@');
      await tester.enterText(passFields.at(1), 'MatKhauMoi2026@');
      await tester.tap(find.text('Lưu Mật Khẩu Mới'));
      await tester.pumpAndSettle();

      expect(recoveredId, equals('STYT-892410'));
    });
  });
}
