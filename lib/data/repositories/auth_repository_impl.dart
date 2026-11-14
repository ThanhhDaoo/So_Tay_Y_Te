import 'package:uuid/uuid.dart';
import '../../core/config/supabase_config.dart';
import '../../core/security/password_hasher.dart';
import '../../domain/entities/auth_identity.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/app_preferences_datasource.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../datasources/remote/supabase_auth_datasource.dart';
import '../models/auth_identity_model.dart';
import '../models/user_account_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AppPreferencesDataSource localDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final SupabaseAuthRemoteDataSource? supabaseAuthRemoteDataSource;
  final Uuid _uuid = const Uuid();

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authLocalDataSource,
    this.supabaseAuthRemoteDataSource,
  });

  @override
  Future<UserProfile?> getCurrentUser() async {
    final sessionUserId = await localDataSource.getSessionUserId();
    if (sessionUserId == null) return null;

    final user = await authLocalDataSource.findById(sessionUserId);
    if (user == null) return null;

    return UserProfile(
      id: user.id,
      fullName: user.fullName,
      bloodType: user.bloodType,
      emergencyContact: user.primaryContact,
      isPro: await localDataSource.getProStatus(),
    );
  }

  @override
  Future<UserProfile> loginAnonymous() async {
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final cloudGuest = await supabaseAuthRemoteDataSource!.signInAnonymously();
        await authLocalDataSource.createUser(cloudGuest);
        await localDataSource.saveSession(
          userId: cloudGuest.id,
          patientCode: cloudGuest.patientCode,
          contact: cloudGuest.primaryContact,
          rememberMe: false,
        );
        return UserProfile(
          id: cloudGuest.id,
          fullName: cloudGuest.fullName,
          emergencyContact: cloudGuest.primaryContact,
          isPro: false,
        );
      } catch (_) {}
    }

    final patientCode = await authLocalDataSource.generateUniquePatientCode();
    final guestId = 'guest-${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hashPassword('guest_auto_pass', salt);

    final guestUser = UserAccountModel(
      id: guestId,
      patientCode: patientCode,
      fullName: 'Bệnh nhân Khách',
      primaryContact: 'guest_$patientCode@sotayyte.local',
      passwordHash: hash,
      salt: salt,
      isGuest: true,
      createdAt: now,
    );

    await authLocalDataSource.createUser(
      guestUser,
      initialIdentity: AuthIdentityModel(
        id: _uuid.v4(),
        userId: guestId,
        provider: AuthProviderType.guest,
        providerUid: guestId,
        linkedAt: now,
      ),
    );

    await localDataSource.saveSession(
      userId: guestId,
      patientCode: patientCode,
      contact: guestUser.primaryContact,
      rememberMe: false,
    );

    return UserProfile(
      id: guestId,
      fullName: guestUser.fullName,
      emergencyContact: guestUser.primaryContact,
      isPro: false,
    );
  }

  @override
  Future<UserProfile> linkAccount({
    required String email,
    required String password,
  }) async {
    final user = await remoteDataSource.linkAccount(
      email: email,
      password: password,
    );
    return user.toEntity();
  }

  @override
  Future<bool> checkProStatus() async {
    return await localDataSource.getProStatus();
  }

  @override
  Future<void> logout() async {
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        await supabaseAuthRemoteDataSource!.signOut();
      } catch (_) {}
    }
    await localDataSource.clearSession();
  }

  @override
  Future<UserAccount> register({
    required String fullName,
    required String contact,
    required String password,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
  }) async {
    // 1. Nếu đã kết nối Supabase Cloud, đăng ký lên Supabase Auth
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final cloudAccount = await supabaseAuthRemoteDataSource!.signUpWithEmail(
          email: contact.trim().toLowerCase(),
          password: password,
          fullName: fullName.trim(),
          dateOfBirth: dateOfBirth,
          gender: gender,
          bloodType: bloodType,
        );

        // Đồng bộ bản ghi xuống CSDL SQLite cục bộ
        await authLocalDataSource.createUser(cloudAccount);
        await localDataSource.saveSession(
          userId: cloudAccount.id,
          patientCode: cloudAccount.patientCode,
          contact: cloudAccount.primaryContact,
          rememberMe: true,
        );
        return cloudAccount;
      } catch (e) {
        throw Exception(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    // 2. Chế độ CSDL Local-First (SQLite + SHA-256 + Salt)
    final existingUser = await authLocalDataSource.findByIdentifier(contact);
    if (existingUser != null) {
      throw Exception('Số điện thoại hoặc Email này đã được đăng ký hồ sơ.');
    }

    final userId = _uuid.v4();
    final patientCode = await authLocalDataSource.generateUniquePatientCode();
    final salt = PasswordHasher.generateSalt();
    final passwordHash = PasswordHasher.hashPassword(password, salt);
    final now = DateTime.now();

    final newUser = UserAccountModel(
      id: userId,
      patientCode: patientCode,
      fullName: fullName.trim(),
      primaryContact: contact.trim().toLowerCase(),
      passwordHash: passwordHash,
      salt: salt,
      dateOfBirth: dateOfBirth,
      gender: gender ?? 'Chưa rõ',
      bloodType: bloodType ?? 'Chưa rõ',
      avatarUrl: 'assets/images/img_profile_avatar.png',
      isGuest: false,
      createdAt: now,
    );

    final isPhone = RegExp(r'^[0-9+]+$').hasMatch(contact.trim());
    final provider = isPhone ? AuthProviderType.phoneOtp : AuthProviderType.emailPassword;

    final created = await authLocalDataSource.createUser(
      newUser,
      initialIdentity: AuthIdentityModel(
        id: _uuid.v4(),
        userId: userId,
        provider: provider,
        providerUid: contact.trim().toLowerCase(),
        emailAssociated: isPhone ? null : contact.trim().toLowerCase(),
        linkedAt: now,
      ),
    );

    await localDataSource.saveSession(
      userId: userId,
      patientCode: patientCode,
      contact: contact.trim().toLowerCase(),
      rememberMe: true,
    );

    return created;
  }

  @override
  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    // 1. Nếu đã kết nối Supabase Cloud và identifier là email
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null && identifier.contains('@')) {
      try {
        final cloudAccount = await supabaseAuthRemoteDataSource!.signInWithEmail(
          email: identifier.trim().toLowerCase(),
          password: password,
        );

        // Lưu session & cập nhật local DB
        await authLocalDataSource.createUser(cloudAccount);
        await localDataSource.saveSession(
          userId: cloudAccount.id,
          patientCode: cloudAccount.patientCode,
          contact: cloudAccount.primaryContact,
          rememberMe: rememberMe,
        );
        return cloudAccount;
      } catch (e) {
        throw Exception(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    // 2. Chế độ CSDL Local-First (SQLite)
    final user = await authLocalDataSource.findByIdentifier(identifier);
    if (user == null) {
      throw Exception('Mã hồ sơ hoặc Email/SĐT chưa được đăng ký trong hệ thống.');
    }

    final isValid = PasswordHasher.verifyPassword(
      password: password,
      salt: user.salt,
      expectedHash: user.passwordHash,
    );

    if (!isValid) {
      throw Exception('Mật khẩu không chính xác. Vui lòng kiểm tra lại.');
    }

    await localDataSource.saveSession(
      userId: user.id,
      patientCode: user.patientCode,
      contact: user.primaryContact,
      rememberMe: rememberMe,
    );

    return user;
  }

  @override
  Future<UserAccount?> getActiveSession() async {
    final rememberMe = await localDataSource.getRememberMe();
    if (!rememberMe) return null;

    final userId = await localDataSource.getSessionUserId();
    if (userId == null) return null;

    return await authLocalDataSource.findById(userId);
  }

  @override
  Future<void> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null && identifier.contains('@')) {
      try {
        await supabaseAuthRemoteDataSource!.resetPassword(identifier.trim().toLowerCase());
        return;
      } catch (e) {
        throw Exception(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    final user = await authLocalDataSource.findByIdentifier(identifier);
    if (user == null) {
      throw Exception('Không tìm thấy tài khoản tương ứng với mã hoặc liên hệ này.');
    }

    final salt = PasswordHasher.generateSalt();
    final newHash = PasswordHasher.hashPassword(newPassword, salt);
    await authLocalDataSource.updatePassword(user.id, newHash, salt);
  }
}
