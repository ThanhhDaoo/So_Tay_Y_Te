import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/firebase_config.dart';
import '../../core/config/supabase_config.dart';
import '../../core/di/injection_container.dart';
import '../../core/security/password_hasher.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/input_validators.dart';
import '../../domain/entities/auth_identity.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/app_preferences_datasource.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../datasources/remote/firebase_auth_datasource.dart';
import '../datasources/remote/supabase_auth_datasource.dart';
import '../models/auth_identity_model.dart';
import '../models/user_account_model.dart';

class _RecoveryOtpRecord {
  final String code;
  final String userId;
  final String targetContact;
  final DateTime expiresAt;

  const _RecoveryOtpRecord({
    required this.code,
    required this.userId,
    required this.targetContact,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AppPreferencesDataSource localDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final SupabaseAuthRemoteDataSource? supabaseAuthRemoteDataSource;
  final FirebaseAuthRemoteDataSource? firebaseAuthRemoteDataSource;
  final Uuid _uuid = const Uuid();
  final Random _secureRandom = Random.secure();
  final Map<String, _RecoveryOtpRecord> _recoveryOtpStore = {};

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authLocalDataSource,
    this.supabaseAuthRemoteDataSource,
    this.firebaseAuthRemoteDataSource,
  });

  bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  Future<void> _pushSimulatedSmsNotification({
    required String contact,
    required String otpCode,
    required String purpose,
  }) async {
    if (_isFlutterTest) return;
    if (!sl.isRegistered<NotificationService>()) return;

    try {
      final notif = sl<NotificationService>();
      await notif.initialize();
      await notif.requestPermissions();
      await notif.showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: '💬 SMS Sổ Tay Y Tế ($contact)',
        body:
            'Mã OTP $purpose của bạn là: $otpCode (Hiệu lực 5 phút). Không chia sẻ mã này cho bất kỳ ai.',
      );
    } catch (e) {
      debugPrint('[AuthRepository] Không thể đẩy thông báo OTP giả lập: $e');
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final sessionUserId = await localDataSource.getSessionUserId();
    if (sessionUserId == null) return null;

    final user = await authLocalDataSource.findById(sessionUserId);
    if (user == null) return null;

    return UserProfile(
      id: user.id,
      fullName: user.fullName,
      dateOfBirth: user.dateOfBirth != null
          ? DateTime.tryParse(user.dateOfBirth!)
          : null,
      bloodType: user.bloodType,
      emergencyContact: user.primaryContact,
      isPro: await localDataSource.getProStatus(),
    );
  }

  @override
  Future<UserProfile> loginAnonymous() async {
    // Kiểm tra nếu trên máy đã có tài khoản Guest trước đó thì tái sử dụng để không mất dữ liệu cục bộ
    final lastSessionId = await localDataSource.getSessionUserId();
    if (lastSessionId != null) {
      final existingGuest = await authLocalDataSource.findById(lastSessionId);
      if (existingGuest != null && existingGuest.isGuest) {
        await localDataSource.saveSession(
          userId: existingGuest.id,
          patientCode: existingGuest.patientCode,
          contact: existingGuest.primaryContact,
          rememberMe: false,
        );
        return UserProfile(
          id: existingGuest.id,
          fullName: existingGuest.fullName,
          emergencyContact: existingGuest.primaryContact,
          isPro: false,
        );
      }
    }

    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final cloudGuest =
            await supabaseAuthRemoteDataSource!.signInAnonymously();
        final savedGuest = await authLocalDataSource.createUser(
          cloudGuest,
          initialIdentity: AuthIdentityModel(
            id: _uuid.v4(),
            userId: cloudGuest.id,
            provider: AuthProviderType.guest,
            providerUid: cloudGuest.id,
            linkedAt: DateTime.now(),
          ),
        );
        await localDataSource.saveSession(
          userId: savedGuest.id,
          patientCode: savedGuest.patientCode,
          contact: savedGuest.primaryContact,
          rememberMe: false,
        );
        return UserProfile(
          id: savedGuest.id,
          fullName: savedGuest.fullName,
          emergencyContact: savedGuest.primaryContact,
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
      fullName: 'Khách (Chưa đăng ký)',
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
    if (firebaseAuthRemoteDataSource != null) {
      try {
        await firebaseAuthRemoteDataSource!.signOut();
      } catch (_) {}
    }
    await localDataSource.clearSession();
  }

  @override
  Future<bool> checkAccountExists(String identifier) async {
    final type = InputValidators.classifyIdentifier(identifier);
    String lookup = identifier.trim();
    if (type == AuthIdentifierType.phone) {
      lookup = InputValidators.normalizePhoneLocal(identifier);
    } else if (type == AuthIdentifierType.email) {
      lookup = identifier.trim().toLowerCase();
    }

    final existingLocal = await authLocalDataSource.findByIdentifier(lookup);
    if (existingLocal != null && !existingLocal.isGuest) {
      return true;
    }

    if (type == AuthIdentifierType.patientCode &&
        SupabaseConfig.isConfigured &&
        supabaseAuthRemoteDataSource != null) {
      final remoteContact =
          await supabaseAuthRemoteDataSource!.lookupContactByPatientCode(lookup);
      if (remoteContact != null) return true;
    }

    return false;
  }

  @override
  Future<UserAccount?> getBiometricBoundAccount() async {
    final boundUserId = await localDataSource.getBiometricUserId();
    if (boundUserId != null && boundUserId.isNotEmpty) {
      final user = await authLocalDataSource.findById(boundUserId);
      if (user != null && !user.isGuest) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<String?> getLastLoginIdentifier() async {
    return await localDataSource.getLastLoginIdentifier();
  }

  @override
  Future<bool> isDeviceAppLockEnabled() async {
    final bio = await localDataSource.isBiometricLockEnabled();
    final pin = await localDataSource.hasPin();
    return bio || pin;
  }

  @override
  Future<UserAccount> register({
    required String fullName,
    required String contact,
    required String password,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    bool enableBiometric = false,
  }) async {
    final nameErr = InputValidators.validateFullName(fullName);
    if (nameErr != null) throw Exception(nameErr);

    final contactErr = InputValidators.validateEmailOrPhone(contact);
    if (contactErr != null) throw Exception(contactErr);

    final passErr = InputValidators.validatePassword(password);
    if (passErr != null) throw Exception(passErr);

    final idType = InputValidators.classifyIdentifier(contact);
    final isPhone = idType == AuthIdentifierType.phone;

    final canonicalContact = isPhone
        ? InputValidators.normalizePhoneLocal(contact)
        : contact.trim().toLowerCase();

    final authEmail = isPhone
        ? '${InputValidators.normalizePhoneE164(contact).replaceAll('+', '')}@sotayyte.vn'
        : canonicalContact;

    // 1. Kiểm tra trùng lặp cục bộ trước khi gọi Cloud
    final existingLocal =
        await authLocalDataSource.findByIdentifier(canonicalContact);
    if (existingLocal != null && !existingLocal.isGuest) {
      throw Exception('Số điện thoại hoặc Email này đã được đăng ký hồ sơ.');
    }

    // Kiểm tra nếu người dùng đang ở phiên Guest để nâng cấp liền mạch
    final previousSessionUserId = await localDataSource.getSessionUserId();
    UserAccountModel? previousGuest;
    if (previousSessionUserId != null) {
      final prev = await authLocalDataSource.findById(previousSessionUserId);
      if (prev != null && prev.isGuest) {
        previousGuest = prev;
      }
    }

    final provisionalCode =
        await authLocalDataSource.generateUniquePatientCode();
    UserAccountModel? cloudAccount;

    // 2. Nếu đã kết nối Supabase Cloud, đăng ký lên Supabase Auth
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final res = await supabaseAuthRemoteDataSource!.signUpWithEmail(
          email: authEmail,
          password: password,
          fullName: fullName.trim(),
          primaryContact: canonicalContact,
          patientCode: provisionalCode,
          dateOfBirth: dateOfBirth,
          gender: gender,
          bloodType: bloodType,
        );

        cloudAccount = UserAccountModel(
          id: res.id,
          patientCode: res.patientCode,
          fullName: res.fullName,
          primaryContact: canonicalContact,
          passwordHash: '',
          salt: '',
          dateOfBirth: dateOfBirth,
          gender: gender,
          bloodType: bloodType,
          createdAt: res.createdAt,
        );
      } on AuthAccountAlreadyExistsException catch (e) {
        throw Exception(e.message);
      } on AuthEmailConfirmationRequiredException {
        rethrow;
      } catch (e) {
        final errText = e.toString().toLowerCase();
        if (errText.contains('quá giới hạn') || errText.contains('rate limit')) {
          rethrow;
        }
        debugPrint(
          '[Supabase] Không thể kết nối đám mây ($e), lưu hồ sơ chế độ Local-First.',
        );
      }
    }

    final userId = cloudAccount?.id ?? _uuid.v4();
    final patientCode = cloudAccount?.patientCode ?? provisionalCode;
    final salt = PasswordHasher.generateSalt();
    final passwordHash = PasswordHasher.hashPassword(password, salt);
    final now = DateTime.now();

    final newUser = UserAccountModel(
      id: userId,
      patientCode: patientCode,
      fullName: fullName.trim(),
      primaryContact: canonicalContact,
      passwordHash: passwordHash,
      salt: salt,
      dateOfBirth: dateOfBirth,
      gender: gender ?? 'Chưa rõ',
      bloodType: bloodType ?? 'Chưa rõ',
      avatarUrl: 'assets/images/img_profile_avatar.png',
      isGuest: false,
      createdAt: now,
    );

    final provider =
        isPhone ? AuthProviderType.phoneOtp : AuthProviderType.emailPassword;

    final created = await authLocalDataSource.createUser(
      newUser,
      initialIdentity: AuthIdentityModel(
        id: _uuid.v4(),
        userId: userId,
        provider: provider,
        providerUid: canonicalContact.toLowerCase(),
        emailAssociated: authEmail,
        linkedAt: now,
      ),
    );

    // Dọn tài khoản Guest tạm sau khi nâng cấp thành công
    if (previousGuest != null && previousGuest.id != created.id) {
      await authLocalDataSource.deleteUserById(previousGuest.id);
    }

    await _persistAuthenticatedSession(
      user: created,
      loginIdentifier: canonicalContact,
      rememberMe: true,
      enableBiometricIfRequested: enableBiometric,
    );

    return created;
  }

  @override
  Future<UserAccount> verifyEmailSignupOtp({
    required String email,
    required String otpCode,
    required String password,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
    bool enableBiometric = false,
  }) async {
    if (!SupabaseConfig.isConfigured || supabaseAuthRemoteDataSource == null) {
      throw Exception('Dịch vụ xác thực Email Cloud chưa sẵn sàng.');
    }

    final canonicalEmail = email.trim().toLowerCase();
    final cloudAccount = await supabaseAuthRemoteDataSource!.verifyEmailOtp(
      email: canonicalEmail,
      token: otpCode.trim(),
      type: OtpType.signup,
    );

    final salt = PasswordHasher.generateSalt();
    final passwordHash = PasswordHasher.hashPassword(password, salt);
    final now = DateTime.now();

    final newUser = UserAccountModel(
      id: cloudAccount.id,
      patientCode: cloudAccount.patientCode,
      fullName: fullName.trim(),
      primaryContact: canonicalEmail,
      passwordHash: passwordHash,
      salt: salt,
      dateOfBirth: dateOfBirth ?? cloudAccount.dateOfBirth,
      gender: gender ?? cloudAccount.gender ?? 'Chưa rõ',
      bloodType: bloodType ?? cloudAccount.bloodType ?? 'Chưa rõ',
      avatarUrl: cloudAccount.avatarUrl ?? 'assets/images/img_profile_avatar.png',
      isGuest: false,
      createdAt: now,
    );

    final created = await authLocalDataSource.createUser(
      newUser,
      initialIdentity: AuthIdentityModel(
        id: _uuid.v4(),
        userId: newUser.id,
        provider: AuthProviderType.emailPassword,
        providerUid: canonicalEmail,
        emailAssociated: canonicalEmail,
        linkedAt: now,
      ),
    );

    await _persistAuthenticatedSession(
      user: created,
      loginIdentifier: canonicalEmail,
      rememberMe: true,
      enableBiometricIfRequested: enableBiometric,
    );

    return created;
  }

  @override
  Future<UserAccount> login({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty || password.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ định danh và mật khẩu.');
    }

    final idType = InputValidators.classifyIdentifier(cleanId);
    final localMatch = await authLocalDataSource.findByIdentifier(cleanId);

    String? resolvedAuthEmail;
    String? resolvedPrimaryContact;

    switch (idType) {
      case AuthIdentifierType.email:
        resolvedPrimaryContact = cleanId.toLowerCase();
        resolvedAuthEmail = resolvedPrimaryContact;
        break;
      case AuthIdentifierType.phone:
        resolvedPrimaryContact = InputValidators.normalizePhoneLocal(cleanId);
        resolvedAuthEmail =
            '${InputValidators.normalizePhoneE164(cleanId).replaceAll('+', '')}@sotayyte.vn';
        break;
      case AuthIdentifierType.patientCode:
        if (localMatch != null && !localMatch.isGuest) {
          resolvedPrimaryContact = localMatch.primaryContact;
        } else if (SupabaseConfig.isConfigured &&
            supabaseAuthRemoteDataSource != null) {
          resolvedPrimaryContact = await supabaseAuthRemoteDataSource!
              .lookupContactByPatientCode(cleanId);
        }

        if (resolvedPrimaryContact != null) {
          final contactType =
              InputValidators.classifyIdentifier(resolvedPrimaryContact);
          if (contactType == AuthIdentifierType.email) {
            resolvedAuthEmail = resolvedPrimaryContact.toLowerCase();
          } else if (contactType == AuthIdentifierType.phone) {
            resolvedAuthEmail =
                '${InputValidators.normalizePhoneE164(resolvedPrimaryContact).replaceAll('+', '')}@sotayyte.vn';
          }
        }
        break;
      case AuthIdentifierType.unknown:
        if (localMatch == null) {
          throw Exception(
            'Định dạng không hợp lệ. Vui lòng nhập SĐT (10 số), Email hoặc Mã hồ sơ (STYT-XXXXXX).',
          );
        }
        resolvedPrimaryContact = localMatch.primaryContact;
        break;
    }

    // 1. Thử xác thực qua Supabase Cloud (nếu giải mã được email xác thực hợp lệ)
    if (SupabaseConfig.isConfigured &&
        supabaseAuthRemoteDataSource != null &&
        resolvedAuthEmail != null &&
        resolvedAuthEmail.contains('@')) {
      try {
        final cloudAccount =
            await supabaseAuthRemoteDataSource!.signInWithEmail(
          email: resolvedAuthEmail,
          password: password,
        );

        // Băm mật khẩu vừa xác thực thành công để lưu vào SQLite phục vụ đăng nhập Offline về sau
        final salt = PasswordHasher.generateSalt();
        final passwordHash = PasswordHasher.hashPassword(password, salt);

        final contactToStore = resolvedPrimaryContact ?? cloudAccount.primaryContact;
        final mappedAccount = UserAccountModel(
          id: cloudAccount.id,
          patientCode: cloudAccount.patientCode,
          fullName: cloudAccount.fullName,
          primaryContact: contactToStore,
          passwordHash: passwordHash,
          salt: salt,
          dateOfBirth: cloudAccount.dateOfBirth,
          gender: cloudAccount.gender,
          bloodType: cloudAccount.bloodType,
          avatarUrl: cloudAccount.avatarUrl ?? 'assets/images/img_profile_avatar.png',
          createdAt: cloudAccount.createdAt,
        );

        final isPhoneContact =
            InputValidators.classifyIdentifier(contactToStore) ==
                AuthIdentifierType.phone;

        final savedAccount = await authLocalDataSource.createUser(
          mappedAccount,
          initialIdentity: AuthIdentityModel(
            id: _uuid.v4(),
            userId: mappedAccount.id,
            provider: isPhoneContact
                ? AuthProviderType.phoneOtp
                : AuthProviderType.emailPassword,
            providerUid: contactToStore.toLowerCase(),
            emailAssociated: resolvedAuthEmail,
            linkedAt: DateTime.now(),
          ),
        );

        await _persistAuthenticatedSession(
          user: savedAccount,
          loginIdentifier: cleanId,
          rememberMe: rememberMe,
        );
        return savedAccount;
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        final isSyntheticPhoneEmail = resolvedAuthEmail.endsWith('@sotayyte.vn');

        if (errStr.contains('email not confirmed') && !isSyntheticPhoneEmail) {
          throw Exception(
            'Địa chỉ Email chưa được xác nhận. Vui lòng mở hộp thư (kiểm tra cả mục Spam) và nhấn vào liên kết xác nhận từ Supabase trước khi đăng nhập.',
          );
        }

        final isInvalidCreds = errStr.contains('invalid login credentials') ||
            errStr.contains('invalid_credentials') ||
            errStr.contains('user not found') ||
            (errStr.contains('email not confirmed') && isSyntheticPhoneEmail);

        if (isInvalidCreds) {
          // Kiểm tra xem tài khoản có tồn tại cục bộ (tạo khi offline hoặc vừa đổi mật khẩu qua OTP) không
          if (localMatch != null &&
              localMatch.passwordHash.isNotEmpty &&
              localMatch.salt.isNotEmpty) {
            final localOk = PasswordHasher.verifyPassword(
              password: password,
              salt: localMatch.salt,
              expectedHash: localMatch.passwordHash,
            );
            if (localOk) {
              await _persistAuthenticatedSession(
                user: localMatch,
                loginIdentifier: cleanId,
                rememberMe: rememberMe,
              );
              return localMatch;
            }
            throw Exception('Mật khẩu không chính xác. Vui lòng kiểm tra lại.');
          }

          throw Exception(
            'Thông tin đăng nhập hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.',
          );
        }

        debugPrint(
          '[Supabase] Đăng nhập Cloud gặp lỗi mạng ($e), chuyển sang xác thực CSDL cục bộ.',
        );
      }
    }

    // 2. Chế độ CSDL Local-First (SQLite)
    if (localMatch == null || localMatch.isGuest) {
      throw Exception(
        'Mã hồ sơ hoặc Email/SĐT chưa được đăng ký trong hệ thống.',
      );
    }

    if (localMatch.passwordHash.isEmpty || localMatch.salt.isEmpty) {
      throw Exception(
        'Tài khoản này được tạo bằng Google/Apple hoặc OTP (chưa đặt mật khẩu). Vui lòng đăng nhập bằng OTP / Mạng xã hội hoặc bấm "Quên mật khẩu?" để tạo mật khẩu mới.',
      );
    }

    final isValid = PasswordHasher.verifyPassword(
      password: password,
      salt: localMatch.salt,
      expectedHash: localMatch.passwordHash,
    );

    if (!isValid) {
      throw Exception('Mật khẩu không chính xác. Vui lòng kiểm tra lại.');
    }

    await _persistAuthenticatedSession(
      user: localMatch,
      loginIdentifier: cleanId,
      rememberMe: rememberMe,
    );

    return localMatch;
  }

  Future<void> _persistAuthenticatedSession({
    required UserAccount user,
    required String loginIdentifier,
    required bool rememberMe,
    bool enableBiometricIfRequested = false,
  }) async {
    await localDataSource.saveSession(
      userId: user.id,
      patientCode: user.patientCode,
      contact: user.primaryContact,
      rememberMe: rememberMe,
    );

    if (rememberMe && !user.isGuest) {
      await localDataSource.saveLastLoginIdentifier(loginIdentifier);
    }

    if (!user.isGuest) {
      if (enableBiometricIfRequested) {
        await localDataSource.setBiometricLockEnabled(true);
      }
      // Luôn ghi nhận user gần nhất đã xác thực trên thiết bị cho nút Face ID / Vân tay nhanh
      await localDataSource.saveBiometricUserId(user.id);
    }
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
    final passErr = InputValidators.validatePassword(newPassword);
    if (passErr != null) throw Exception(passErr);

    final user = await authLocalDataSource.findByIdentifier(identifier.trim());
    if (user == null || user.isGuest) {
      if (SupabaseConfig.isConfigured &&
          supabaseAuthRemoteDataSource != null &&
          identifier.contains('@')) {
        await supabaseAuthRemoteDataSource!
            .resetPassword(identifier.trim().toLowerCase());
        return;
      }
      throw Exception(
        'Không tìm thấy tài khoản tương ứng với mã hoặc liên hệ này.',
      );
    }

    final salt = PasswordHasher.generateSalt();
    final newHash = PasswordHasher.hashPassword(newPassword, salt);
    await authLocalDataSource.updatePassword(user.id, newHash, salt);

    // Nếu đang có phiên Cloud của đúng user này thì đồng bộ mật khẩu Cloud luôn
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final cloudUser = supabaseAuthRemoteDataSource!.currentAuthUser;
        if (cloudUser != null && cloudUser.id == user.id) {
          await supabaseAuthRemoteDataSource!.updateCloudPassword(newPassword);
        }
      } catch (_) {}
    }
  }

  @override
  Future<PasswordRecoveryChallenge> sendPasswordRecoveryChallenge(
    String identifier,
  ) async {
    final cleanId = identifier.trim();
    final idType = InputValidators.classifyIdentifier(cleanId);
    if (idType == AuthIdentifierType.unknown) {
      throw Exception(
        'Vui lòng nhập đúng Email, Số điện thoại hoặc Mã hồ sơ (STYT-XXXXXX).',
      );
    }

    final localUser = await authLocalDataSource.findByIdentifier(cleanId);

    // Nếu người dùng nhập Email Cloud chưa có trong bộ nhớ máy -> gửi Email khôi phục qua Supabase
    if ((localUser == null || localUser.isGuest) &&
        idType == AuthIdentifierType.email &&
        SupabaseConfig.isConfigured &&
        supabaseAuthRemoteDataSource != null) {
      await supabaseAuthRemoteDataSource!.resetPassword(cleanId.toLowerCase());
      return PasswordRecoveryChallenge(
        verificationId: 'supabase-email-link',
        maskedContact: InputValidators.maskContact(cleanId.toLowerCase()),
        targetContact: cleanId.toLowerCase(),
        isEmailLinkSent: true,
      );
    }

    if (localUser == null || localUser.isGuest) {
      throw Exception(
        'Không tìm thấy hồ sơ y tế nào đăng ký với thông tin "$cleanId".',
      );
    }

    // Tạo thử thách OTP 6 số xác minh danh tính chủ hồ sơ
    _recoveryOtpStore.removeWhere((_, rec) => rec.isExpired);
    final verificationId =
        'rec-ver-${DateTime.now().millisecondsSinceEpoch}-${_secureRandom.nextInt(999999)}';
    final otpCode = (_secureRandom.nextInt(900000) + 100000).toString();

    _recoveryOtpStore[verificationId] = _RecoveryOtpRecord(
      code: otpCode,
      userId: localUser.id,
      targetContact: localUser.primaryContact,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );

    final masked = InputValidators.maskContact(localUser.primaryContact);

    // Nếu liên hệ của hồ sơ là Email và có kết nối Supabase, gửi đồng thời email khôi phục dự phòng
    if (localUser.primaryContact.contains('@') &&
        SupabaseConfig.isConfigured &&
        supabaseAuthRemoteDataSource != null) {
      try {
        await supabaseAuthRemoteDataSource!
            .resetPassword(localUser.primaryContact.toLowerCase());
      } catch (_) {}
    }

    await _pushSimulatedSmsNotification(
      contact: masked,
      otpCode: otpCode,
      purpose: 'khôi phục mật khẩu',
    );

    return PasswordRecoveryChallenge(
      verificationId: verificationId,
      maskedContact: masked,
      targetContact: localUser.primaryContact,
      isEmailLinkSent: false,
      sandboxOtpPreview: FirebaseConfig.isConfigured ? null : otpCode,
    );
  }

  @override
  Future<void> verifyRecoveryAndResetPassword({
    required String identifier,
    required String verificationId,
    required String otpCode,
    required String newPassword,
  }) async {
    final passErr = InputValidators.validatePassword(newPassword);
    if (passErr != null) throw Exception(passErr);

    final cleanOtp = otpCode.trim();
    if (cleanOtp.length != 6) {
      throw Exception('Vui lòng nhập đủ 6 chữ số mã xác minh danh tính.');
    }

    final record = _recoveryOtpStore[verificationId];
    if (record == null) {
      throw Exception(
        'Phiên xác minh không hợp lệ hoặc đã hết hạn. Vui lòng gửi lại mã.',
      );
    }
    if (record.isExpired) {
      _recoveryOtpStore.remove(verificationId);
      throw Exception('Mã xác minh đã hết hạn (quá 5 phút). Vui lòng lấy mã mới.');
    }

    final isMatch = record.code == cleanOtp ||
        (!FirebaseConfig.isConfigured && cleanOtp == '123456');
    if (!isMatch) {
      throw Exception('Mã xác minh danh tính không chính xác.');
    }

    _recoveryOtpStore.remove(verificationId);

    final salt = PasswordHasher.generateSalt();
    final newHash = PasswordHasher.hashPassword(newPassword, salt);
    await authLocalDataSource.updatePassword(record.userId, newHash, salt);

    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final cloudUser = supabaseAuthRemoteDataSource!.currentAuthUser;
        if (cloudUser != null && cloudUser.id == record.userId) {
          await supabaseAuthRemoteDataSource!.updateCloudPassword(newPassword);
        }
      } catch (_) {}
    }
  }

  @override
  String? peekSandboxOtp(String verificationId) {
    if (FirebaseConfig.isConfigured) return null;
    if (verificationId.startsWith('rec-ver-')) {
      final rec = _recoveryOtpStore[verificationId];
      if (rec != null && !rec.isExpired) return rec.code;
    }
    return firebaseAuthRemoteDataSource?.peekSandboxOtp(verificationId);
  }

  @override
  Future<String> sendPhoneOtp(String phoneNumber) async {
    final phoneErr = InputValidators.validatePhone(phoneNumber);
    if (phoneErr != null) {
      throw Exception(phoneErr);
    }

    final normalized = InputValidators.normalizePhoneE164(phoneNumber);
    final localPhone = InputValidators.normalizePhoneLocal(phoneNumber);

    // 1. Ưu tiên Firebase Auth Phone Service nếu đã cấu hình Production Key
    if (FirebaseConfig.isConfigured && firebaseAuthRemoteDataSource != null) {
      try {
        return await firebaseAuthRemoteDataSource!.sendPhoneOtp(normalized);
      } catch (e) {
        throw Exception(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    // 2. Thử Supabase Phone SMS Gateway nếu đã cấu hình trên Dashboard
    if (SupabaseConfig.isConfigured &&
        supabaseAuthRemoteDataSource != null &&
        !_isFlutterTest) {
      try {
        await supabaseAuthRemoteDataSource!.sendPhoneOtp(phone: normalized);
        return 'sb-ver-${DateTime.now().millisecondsSinceEpoch}';
      } catch (e) {
        final err = e.toString().toLowerCase();
        final isGatewayUnconfigured = err.contains('phone_provider_disabled') ||
            err.contains('unsupported phone provider') ||
            err.contains('sms') ||
            err.contains('twilio') ||
            err.contains('vonage') ||
            err.contains('messagebird');
        if (!isGatewayUnconfigured) {
          throw Exception(e.toString().replaceFirst('Exception: ', ''));
        }
        debugPrint(
          '[PhoneAuth] Supabase SMS Gateway chưa kích hoạt, chuyển sang OTP Engine nội bộ.',
        );
      }
    }

    // 3. Fallback Firebase Sandbox / OTP Engine có thông báo Push SMS trực tiếp
    if (firebaseAuthRemoteDataSource != null) {
      final verId = await firebaseAuthRemoteDataSource!.sendPhoneOtp(normalized);
      final generatedCode =
          firebaseAuthRemoteDataSource!.peekSandboxOtp(verId);
      if (generatedCode != null) {
        await _pushSimulatedSmsNotification(
          contact: localPhone,
          otpCode: generatedCode,
          purpose: 'xác thực SĐT',
        );
      }
      return verId;
    }

    return 'ver-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<UserAccount> verifyPhoneOtp({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    final normalized = InputValidators.normalizePhoneE164(phoneNumber);
    final localPhone = InputValidators.normalizePhoneLocal(phoneNumber);
    final cleanCode = smsCode.trim();
    UserAccountModel? remoteAccount;

    // 1. Nếu mã được gửi từ Supabase SMS Gateway thật -> bắt buộc xác thực qua Supabase
    if (verificationId.startsWith('sb-ver-') &&
        SupabaseConfig.isConfigured &&
        supabaseAuthRemoteDataSource != null) {
      try {
        remoteAccount = await supabaseAuthRemoteDataSource!.verifyPhoneOtp(
          phone: normalized,
          token: cleanCode,
        );
      } catch (e) {
        throw Exception(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } else if (firebaseAuthRemoteDataSource != null) {
      // 2. Xác thực qua Firebase / Sandbox OTP Store (ném lỗi ngay nếu sai hoặc hết hạn)
      remoteAccount = await firebaseAuthRemoteDataSource!.verifyPhoneOtp(
        phoneNumber: normalized,
        verificationId: verificationId,
        smsCode: cleanCode,
      );
    } else {
      final isTestPhone =
          (normalized == '+84362625218' && cleanCode == '132005') ||
              (normalized == '+84971860620' && cleanCode == '131205') ||
              cleanCode == '123456';
      if (!isTestPhone) {
        throw Exception('Mã xác thực OTP không chính xác.');
      }
      final patientCode =
          await authLocalDataSource.generateUniquePatientCode();
      remoteAccount = UserAccountModel(
        id: 'usr-phone-${DateTime.now().millisecondsSinceEpoch}',
        patientCode: patientCode,
        fullName: 'Chủ hồ sơ ($localPhone)',
        primaryContact: localPhone,
        passwordHash: '',
        salt: '',
        createdAt: DateTime.now(),
      );
    }

    // 3. Tra cứu tài khoản hiện có theo SĐT để bảo toàn hồ sơ cũ, hoặc khởi tạo mới
    final existingUser = await authLocalDataSource.findByIdentifier(localPhone);
    UserAccount finalUser;

    if (existingUser != null && !existingUser.isGuest) {
      finalUser = existingUser;
    } else {
      final patientCode = remoteAccount.patientCode.isNotEmpty
          ? remoteAccount.patientCode
          : await authLocalDataSource.generateUniquePatientCode();
      final userId =
          remoteAccount.id.startsWith('fb-uid-') || remoteAccount.id.startsWith('usr-phone-')
              ? _uuid.v4()
              : remoteAccount.id;
      final now = DateTime.now();

      final newUser = UserAccountModel(
        id: userId,
        patientCode: patientCode,
        fullName: remoteAccount.fullName.contains('+84')
            ? 'Chủ hồ sơ ($localPhone)'
            : remoteAccount.fullName,
        primaryContact: localPhone,
        passwordHash: '',
        salt: '',
        dateOfBirth: remoteAccount.dateOfBirth,
        gender: remoteAccount.gender,
        bloodType: remoteAccount.bloodType,
        avatarUrl: 'assets/images/img_profile_avatar.png',
        isGuest: false,
        createdAt: now,
      );

      finalUser = await authLocalDataSource.createUser(
        newUser,
        initialIdentity: AuthIdentityModel(
          id: _uuid.v4(),
          userId: userId,
          provider: AuthProviderType.phoneOtp,
          providerUid: localPhone,
          emailAssociated: normalized,
          linkedAt: now,
        ),
      );
    }

    await _persistAuthenticatedSession(
      user: finalUser,
      loginIdentifier: localPhone,
      rememberMe: true,
    );

    return finalUser;
  }

  @override
  Future<void> verifyPhoneOtpOnly({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    final normalized = InputValidators.normalizePhoneE164(phoneNumber);
    final cleanCode = smsCode.trim();

    if (verificationId.startsWith('sb-ver-') &&
        SupabaseConfig.isConfigured &&
        supabaseAuthRemoteDataSource != null) {
      await supabaseAuthRemoteDataSource!.verifyPhoneOtp(
        phone: normalized,
        token: cleanCode,
      );
      return;
    }

    if (firebaseAuthRemoteDataSource != null) {
      await firebaseAuthRemoteDataSource!.verifyPhoneOtp(
        phoneNumber: normalized,
        verificationId: verificationId,
        smsCode: cleanCode,
      );
      return;
    }

    final isTestPhone =
        (normalized == '+84362625218' && cleanCode == '132005') ||
            (normalized == '+84971860620' && cleanCode == '131205') ||
            cleanCode == '123456';
    if (!isTestPhone) {
      throw Exception('Mã xác thực OTP không chính xác.');
    }
  }

  @override
  Future<UserAccount> completePhoneProfileSetup({
    required String userId,
    required String fullName,
    String? bloodType,
    String? gender,
    String? dateOfBirth,
  }) async {
    final nameErr = InputValidators.validateFullName(fullName);
    if (nameErr != null) throw Exception(nameErr);

    final updated = await authLocalDataSource.updateProfileFields(
      userId: userId,
      fullName: fullName.trim(),
      bloodType: bloodType,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );

    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        await supabaseAuthRemoteDataSource!.updateCloudUserMetadata({
          'full_name': fullName.trim(),
          'blood_type': ?bloodType,
          'gender': ?gender,
          'date_of_birth': ?dateOfBirth,
        });
      } catch (_) {}
    }

    if (updated == null) {
      throw Exception('Không thể cập nhật thông tin chủ hồ sơ.');
    }
    return updated;
  }

  @override
  Future<UserAccount> signInWithSocialProvider({
    required String provider,
    String? idToken,
    String? accessToken,
  }) async {
    final isApple = provider.toLowerCase() == 'apple';
    final providerName = isApple ? 'Apple ID' : 'Google';
    final oauthProvider = isApple ? OAuthProvider.apple : OAuthProvider.google;

    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        // Nếu đã có native ID Token (VD: từ Sign in with Apple / Google SDK), xác thực trực tiếp
        if (idToken != null && idToken.isNotEmpty) {
          final cloudUser =
              await supabaseAuthRemoteDataSource!.signInWithIdToken(
            provider: oauthProvider,
            idToken: idToken,
            accessToken: accessToken,
          );
          return await syncSupabaseUserSession(
            userId: cloudUser.id,
            email: cloudUser.primaryContact,
            fullName: cloudUser.fullName,
            avatarUrl: cloudUser.avatarUrl,
            provider: provider,
          );
        }

        // Mở luồng OAuth 2.0 PKCE trên trình duyệt hệ thống và chờ Deep Link callback
        await supabaseAuthRemoteDataSource!.signInWithOAuth(oauthProvider);

        return UserAccountModel(
          id: 'oauth_in_progress',
          patientCode: 'STYT-OAUTH',
          fullName: 'Đang xác thực $providerName...',
          primaryContact: '$providerName-auth',
          passwordHash: '',
          salt: '',
          createdAt: DateTime.now(),
        );
      } catch (e) {
        final err = e.toString();
        if (err.contains('not enabled') ||
            err.contains('Unsupported provider')) {
          throw Exception(
            'Đăng nhập bằng $providerName chưa được bật trên Supabase Console.\n'
            'Vui lòng bật $providerName trong Authentication -> Providers hoặc đăng nhập bằng SĐT / Email.',
          );
        }
        throw Exception(err.replaceFirst('Exception: ', ''));
      }
    }

    throw Exception(
      'Phương thức $providerName cần kết nối đám mây Supabase OAuth.\n'
      'Vui lòng sử dụng Đăng ký / Đăng nhập bằng Số điện thoại hoặc Email.',
    );
  }

  @override
  Future<UserAccount> syncSupabaseUserSession({
    required String userId,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? provider,
  }) async {
    final client = SupabaseConfig.client;
    final cleanEmail = email?.trim().toLowerCase();

    // Kiểm tra xem email này đã có hồ sơ cục bộ trước đó chưa để giữ nguyên Mã STYT-XXXXXX
    final existingLocal = cleanEmail != null
        ? await authLocalDataSource.findByIdentifier(cleanEmail)
        : await authLocalDataSource.findById(userId);

    String patientCode = existingLocal != null && !existingLocal.isGuest
        ? existingLocal.patientCode
        : SupabaseAuthRemoteDataSourceImpl.derivePatientCodeFromUserId(userId);

    String resolvedName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : (existingLocal?.fullName ??
            (cleanEmail != null ? cleanEmail.split('@').first : 'Chủ hồ sơ'));

    String? dob = existingLocal?.dateOfBirth;
    String? gender = existingLocal?.gender;
    String? bloodType = existingLocal?.bloodType;

    if (client != null) {
      try {
        final authUser = client.auth.currentUser;
        final meta = authUser?.userMetadata ?? const <String, dynamic>{};
        if (meta['patient_code'] is String &&
            (meta['patient_code'] as String).trim().isNotEmpty) {
          patientCode = (meta['patient_code'] as String).trim().toUpperCase();
        } else {
          try {
            await client.auth.updateUser(
              UserAttributes(data: {'patient_code': patientCode}),
            );
          } catch (_) {}
        }

        dob ??= meta['date_of_birth'] as String?;
        gender ??= meta['gender'] as String?;
        bloodType ??= meta['blood_type'] as String?;

        final profileRes = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (profileRes != null) {
          patientCode =
              (profileRes['patient_code'] as String?) ?? patientCode;
          resolvedName =
              (profileRes['full_name'] as String?) ?? resolvedName;
          dob ??= profileRes['date_of_birth'] as String?;
          gender ??= profileRes['gender'] as String?;
          bloodType ??= profileRes['blood_type'] as String?;
        } else {
          await client.from('profiles').upsert({
            'id': userId,
            'patient_code': patientCode,
            'full_name': resolvedName,
            'primary_phone': cleanEmail,
          });
        }
      } catch (e) {
        debugPrint('[Supabase] syncSupabaseUserSession metadata/profile sync: $e');
      }
    }

    final resolvedContact = cleanEmail ?? '$userId@auth.supabase';
    final account = UserAccountModel(
      id: userId,
      patientCode: patientCode,
      fullName: resolvedName,
      primaryContact: resolvedContact,
      passwordHash: existingLocal?.passwordHash ?? '',
      salt: existingLocal?.salt ?? '',
      dateOfBirth: dob,
      gender: gender,
      bloodType: bloodType,
      avatarUrl:
          avatarUrl ?? existingLocal?.avatarUrl ?? 'assets/images/img_profile_avatar.png',
      createdAt: existingLocal?.createdAt ?? DateTime.now(),
    );

    final authProviderType = provider?.toLowerCase() == 'apple'
        ? AuthProviderType.apple
        : AuthProviderType.google;

    final saved = await authLocalDataSource.createUser(
      account,
      initialIdentity: AuthIdentityModel(
        id: _uuid.v4(),
        userId: userId,
        provider: authProviderType,
        providerUid: userId,
        emailAssociated: cleanEmail,
        linkedAt: DateTime.now(),
      ),
    );

    await _persistAuthenticatedSession(
      user: saved,
      loginIdentifier: resolvedContact,
      rememberMe: true,
    );

    return saved;
  }
}
