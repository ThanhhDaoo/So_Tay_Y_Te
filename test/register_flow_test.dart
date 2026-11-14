import 'package:flutter_test/flutter_test.dart';
import 'package:so_tay_y_te/domain/entities/user_account.dart';
import 'package:so_tay_y_te/domain/entities/user_profile.dart';
import 'package:so_tay_y_te/domain/repositories/auth_repository.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/register_state.dart';
import 'package:so_tay_y_te/presentation/features/auth/viewmodel/register_viewmodel.dart';

class MockTestAuthRepository implements AuthRepository {
  final Map<String, UserAccount> _users = {};

  @override
  Future<UserAccount> register({
    required String fullName,
    required String contact,
    required String password,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
  }) async {
    if (_users.containsKey(contact)) {
      throw Exception('Số điện thoại hoặc Email này đã được đăng ký hồ sơ.');
    }

    final user = UserAccount(
      id: 'mock-user-123',
      patientCode: 'STYT-123456',
      fullName: fullName,
      primaryContact: contact,
      passwordHash: 'hashed_password',
      salt: 'salt_123',
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodType: bloodType,
      createdAt: DateTime.now(),
    );

    _users[contact] = user;
    return user;
  }

  @override
  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final user = _users[identifier];
    if (user == null) {
      throw Exception('Tài khoản không tồn tại.');
    }
    return user;
  }

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<UserProfile> loginAnonymous() async => const UserProfile(id: 'guest', fullName: 'Guest');

  @override
  Future<UserProfile> linkAccount({required String email, required String password}) async => const UserProfile(id: 'linked', fullName: 'Linked');

  @override
  Future<bool> checkProStatus() async => false;

  @override
  Future<void> logout() async {}

  @override
  Future<UserAccount?> getActiveSession() async => null;

  @override
  Future<void> resetPassword({required String identifier, required String newPassword}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sub-module 1.2: Clinical Registration Flow Tests', () {
    late RegisterViewModel viewModel;
    late MockTestAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockTestAuthRepository();
      viewModel = RegisterViewModel(authRepository: mockRepo);
    });

    test('Initial state is valid with default values', () {
      expect(viewModel.state.status, equals(RegisterStatus.initial));
      expect(viewModel.state.gender, equals('Nam'));
      expect(viewModel.state.bloodType, equals('O+'));
      expect(viewModel.state.acceptedTerms, isTrue);
    });

    test('Password mismatch fails validation with error message', () async {
      viewModel.fullNameController.text = 'Trần Thanh Đạo';
      viewModel.contactController.text = 'thanhdao@icloud.com';
      viewModel.passwordController.text = 'Password123@';
      viewModel.confirmPasswordController.text = 'DifferentPassword123@';

      final success = await viewModel.submitRegistration();

      expect(success, isFalse);
      expect(viewModel.state.status, equals(RegisterStatus.error));
      expect(viewModel.state.errorMessage, contains('không khớp'));
    });

    test('Unaccepted terms fails registration', () async {
      viewModel.toggleAcceptedTerms(false);
      viewModel.fullNameController.text = 'Trần Thanh Đạo';
      viewModel.contactController.text = 'thanhdao@icloud.com';
      viewModel.passwordController.text = 'Password123@';
      viewModel.confirmPasswordController.text = 'Password123@';

      final success = await viewModel.submitRegistration();

      expect(success, isFalse);
      expect(viewModel.state.errorMessage, contains('HIPAA'));
    });

    test('Successful registration creates UserAccount with patientCode', () async {
      viewModel.fullNameController.text = 'Trần Thanh Đạo';
      viewModel.contactController.text = 'thanhdao@icloud.com';
      viewModel.passwordController.text = 'Password123@';
      viewModel.confirmPasswordController.text = 'Password123@';
      viewModel.setBloodType('AB+');
      viewModel.setGender('Nam');

      final success = await viewModel.submitRegistration();

      expect(success, isTrue);
      expect(viewModel.state.status, equals(RegisterStatus.success));
      expect(viewModel.state.createdAccount, isNotNull);
      expect(viewModel.state.createdAccount!.patientCode, equals('STYT-123456'));
      expect(viewModel.state.createdAccount!.bloodType, equals('AB+'));
    });

    test('Duplicate contact registration displays friendly error', () async {
      viewModel.fullNameController.text = 'Trần Thanh Đạo';
      viewModel.contactController.text = 'thanhdao@icloud.com';
      viewModel.passwordController.text = 'Password123@';
      viewModel.confirmPasswordController.text = 'Password123@';

      await viewModel.submitRegistration();

      // Submit second time with same contact
      final secondSuccess = await viewModel.submitRegistration();
      expect(secondSuccess, isFalse);
      expect(viewModel.state.errorMessage, contains('đã được đăng ký'));
    });
  });
}
