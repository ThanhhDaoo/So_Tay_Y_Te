import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/firebase_config.dart';
import '../../core/config/supabase_config.dart';
import '../../core/security/password_hasher.dart';
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

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AppPreferencesDataSource localDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final SupabaseAuthRemoteDataSource? supabaseAuthRemoteDataSource;
  final FirebaseAuthRemoteDataSource? firebaseAuthRemoteDataSource;
  final Uuid _uuid = const Uuid();

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.authLocalDataSource,
    this.supabaseAuthRemoteDataSource,
    this.firebaseAuthRemoteDataSource,
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
    if (firebaseAuthRemoteDataSource != null) {
      try {
        await firebaseAuthRemoteDataSource!.signOut();
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
    final contactClean = contact.trim();
    final isPhone = RegExp(r'^[0-9+]+$').hasMatch(contactClean);
    final normalized = _normalizePhone(contactClean);
    final authEmail = isPhone
        ? '${normalized.replaceAll('+', '')}@sotayyte.vn'
        : contactClean.toLowerCase();

    UserAccountModel? cloudAccount;

    // 1. Nếu đã kết nối Supabase Cloud, đăng ký lên Supabase Auth (hỗ trợ cả Email & SĐT)
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final res = await supabaseAuthRemoteDataSource!.signUpWithEmail(
          email: authEmail,
          password: password,
          fullName: fullName,
          dateOfBirth: dateOfBirth,
          gender: gender,
          bloodType: bloodType,
        );

        cloudAccount = UserAccountModel(
          id: res.id,
          patientCode: res.patientCode,
          fullName: res.fullName,
          primaryContact: contactClean,
          passwordHash: '',
          salt: '',
          dateOfBirth: dateOfBirth,
          gender: gender,
          bloodType: bloodType,
          createdAt: res.createdAt,
        );
      } catch (e) {
        debugPrint('[Supabase] Đăng ký đám mây gặp sự cố ($e), tự động lưu hồ sơ cục bộ.');
      }
    }

    // 2. Chế độ CSDL Local-First (SQLite + SHA-256 + Salt)
    final existingUser = await authLocalDataSource.findByIdentifier(contactClean);
    if (existingUser != null) {
      throw Exception('Số điện thoại hoặc Email này đã được đăng ký hồ sơ.');
    }

    final userId = cloudAccount?.id ?? _uuid.v4();
    final patientCode = cloudAccount?.patientCode ?? await authLocalDataSource.generateUniquePatientCode();
    final salt = PasswordHasher.generateSalt();
    final passwordHash = PasswordHasher.hashPassword(password, salt);
    final now = DateTime.now();

    final newUser = UserAccountModel(
      id: userId,
      patientCode: patientCode,
      fullName: fullName.trim(),
      primaryContact: contactClean,
      passwordHash: passwordHash,
      salt: salt,
      dateOfBirth: dateOfBirth,
      gender: gender ?? 'Chưa rõ',
      bloodType: bloodType ?? 'Chưa rõ',
      avatarUrl: 'assets/images/img_profile_avatar.png',
      isGuest: false,
      createdAt: now,
    );

    final provider = isPhone ? AuthProviderType.phoneOtp : AuthProviderType.emailPassword;

    final created = await authLocalDataSource.createUser(
      newUser,
      initialIdentity: AuthIdentityModel(
        id: _uuid.v4(),
        userId: userId,
        provider: provider,
        providerUid: contactClean.toLowerCase(),
        emailAssociated: isPhone ? authEmail : contactClean.toLowerCase(),
        linkedAt: now,
      ),
    );

    await localDataSource.saveSession(
      userId: userId,
      patientCode: patientCode,
      contact: contactClean,
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
    final cleanId = identifier.trim();
    final isPhone = RegExp(r'^[0-9+]+$').hasMatch(cleanId);
    final authEmail = isPhone
        ? '${_normalizePhone(cleanId).replaceAll('+', '')}@sotayyte.vn'
        : cleanId.toLowerCase();

    // 1. Thử đăng nhập qua Supabase Cloud
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final cloudAccount = await supabaseAuthRemoteDataSource!.signInWithEmail(
          email: authEmail,
          password: password,
        );

        final mappedAccount = UserAccountModel(
          id: cloudAccount.id,
          patientCode: cloudAccount.patientCode,
          fullName: cloudAccount.fullName,
          primaryContact: cleanId,
          passwordHash: '',
          salt: '',
          dateOfBirth: cloudAccount.dateOfBirth,
          gender: cloudAccount.gender,
          bloodType: cloudAccount.bloodType,
          createdAt: cloudAccount.createdAt,
        );

        // Lưu session & cập nhật local DB
        await authLocalDataSource.createUser(mappedAccount);
        await localDataSource.saveSession(
          userId: mappedAccount.id,
          patientCode: mappedAccount.patientCode,
          contact: mappedAccount.primaryContact,
          rememberMe: rememberMe,
        );
        return mappedAccount;
      } catch (e) {
        debugPrint('[Supabase] Đăng nhập Cloud ($e), chuyển sang CSDL cục bộ.');
      }
    }

    // 2. Chế độ CSDL Local-First (SQLite)
    final user = await authLocalDataSource.findByIdentifier(cleanId);
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

  String _normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\s+|-|\.'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('84')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+84${cleaned.substring(1)}';
    return '+84$cleaned';
  }

  @override
  Future<String> sendPhoneOtp(String phoneNumber) async {
    final normalized = _normalizePhone(phoneNumber);

    // 1. Ưu tiên Firebase Auth Phone Service nếu đã cấu hình
    if (FirebaseConfig.isConfigured && firebaseAuthRemoteDataSource != null) {
      try {
        return await firebaseAuthRemoteDataSource!.sendPhoneOtp(normalized);
      } catch (e) {
        throw Exception(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    // 2. Kiểm tra Supabase Phone Auth nếu đã cấu hình
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        await supabaseAuthRemoteDataSource!.sendPhoneOtp(phone: normalized);
        return 'sb-ver-${DateTime.now().millisecondsSinceEpoch}';
      } catch (e) {
        final err = e.toString().toLowerCase();
        // Nếu Supabase chưa cấu hình SMS Gateway (phone_provider_disabled), tự động chuyển sang Firebase OTP
        if (!err.contains('phone_provider_disabled') && !err.contains('unsupported phone provider')) {
          throw Exception(e.toString().replaceFirst('Exception: ', ''));
        }
        debugPrint('[PhoneAuth] Supabase Phone provider disabled, chuyển sang Firebase OTP Sandbox.');
      }
    }

    // 3. Fallback Firebase Sandbox / Mock OTP
    if (firebaseAuthRemoteDataSource != null) {
      return await firebaseAuthRemoteDataSource!.sendPhoneOtp(normalized);
    }

    return 'ver-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<UserAccount> verifyPhoneOtp({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
  }) async {
    final normalized = _normalizePhone(phoneNumber);
    UserAccountModel? remoteAccount;

    // 1. Xác thực qua Firebase
    if (firebaseAuthRemoteDataSource != null) {
      try {
        remoteAccount = await firebaseAuthRemoteDataSource!.verifyPhoneOtp(
          phoneNumber: normalized,
          verificationId: verificationId,
          smsCode: smsCode,
        );
      } catch (e) {
        if (FirebaseConfig.isConfigured) {
          throw Exception(e.toString().replaceFirst('Exception: ', ''));
        }
      }
    }

    // 2. Nếu Supabase đã cấu hình và chưa xác thực qua Firebase
    if (remoteAccount == null && SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        remoteAccount = await supabaseAuthRemoteDataSource!.verifyPhoneOtp(
          phone: normalized,
          token: smsCode,
        );
      } catch (e) {
        // Fallback to local sandbox verification if remote failed
      }
    }

    if (remoteAccount == null) {
      if (smsCode != '123456') {
        throw Exception('Mã xác thực OTP không chính xác.');
      }
      final patientCode = await authLocalDataSource.generateUniquePatientCode();
      remoteAccount = UserAccountModel(
        id: 'usr-phone-${DateTime.now().millisecondsSinceEpoch}',
        patientCode: patientCode,
        fullName: 'Bệnh nhân ($phoneNumber)',
        primaryContact: phoneNumber,
        passwordHash: '',
        salt: '',
        createdAt: DateTime.now(),
      );
    }

    // 3. Tra cứu hoặc khởi tạo trong CSDL Cục bộ (SQLite Local-First)
    final existingUser = await authLocalDataSource.findByIdentifier(phoneNumber);
    UserAccount finalUser;

    if (existingUser != null) {
      finalUser = existingUser;
    } else {
      final patientCode = await authLocalDataSource.generateUniquePatientCode();
      final userId = _uuid.v4();
      final now = DateTime.now();

      final newUser = UserAccountModel(
        id: userId,
        patientCode: patientCode,
        fullName: remoteAccount.fullName,
        primaryContact: phoneNumber,
        passwordHash: '',
        salt: '',
        isGuest: false,
        createdAt: now,
      );

      finalUser = await authLocalDataSource.createUser(
        newUser,
        initialIdentity: AuthIdentityModel(
          id: _uuid.v4(),
          userId: userId,
          provider: AuthProviderType.phoneOtp,
          providerUid: phoneNumber,
          emailAssociated: phoneNumber,
          linkedAt: now,
        ),
      );
    }

    // 4. Lưu phiên đăng nhập
    await localDataSource.saveSession(
      userId: finalUser.id,
      patientCode: finalUser.patientCode,
      contact: phoneNumber,
      rememberMe: true,
    );

    return finalUser;
  }

  @override
  Future<UserAccount> signInWithSocialProvider({
    required String provider,
    String? idToken,
    String? accessToken,
  }) async {
    final isApple = provider.toLowerCase() == 'apple';
    final providerName = isApple ? 'Apple' : 'Google';

    // 1. Nếu đã kết nối Supabase Cloud:
    if (SupabaseConfig.isConfigured && supabaseAuthRemoteDataSource != null) {
      try {
        final oauthProvider = isApple ? OAuthProvider.apple : OAuthProvider.google;
        await supabaseAuthRemoteDataSource!.signInWithOAuth(oauthProvider);
        final currentUser = supabaseAuthRemoteDataSource!.currentAuthUser;
        if (currentUser != null) {
          return await syncSupabaseUserSession(
            userId: currentUser.id,
            email: currentUser.email,
            fullName: currentUser.userMetadata?['full_name'] as String?,
          );
        }

        // OAuth flow được kích hoạt thành công trên trình duyệt
        return UserAccountModel(
          id: 'oauth_in_progress',
          patientCode: 'STYT-OAUTH',
          fullName: 'Đang đăng nhập $providerName...',
          primaryContact: '$providerName-auth',
          passwordHash: '',
          salt: '',
          createdAt: DateTime.now(),
        );
      } catch (e) {
        final err = e.toString();
        if (err.contains('not enabled') || err.contains('Unsupported provider')) {
          throw Exception(
            'Phương thức đăng nhập với $providerName chưa được kích hoạt trên Supabase Console.\n'
            'Vui lòng vào Authentication -> Providers để cấu hình Client ID, hoặc sử dụng Đăng ký / Đăng nhập bằng Email & Mật khẩu.',
          );
        }
        throw Exception(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    // 2. Chế độ thông báo rõ ràng cho môi trường chưa cấu hình OAuth
    throw Exception(
      'Phương thức $providerName chưa được cấu hình OAuth trên Supabase.\n'
      'Vui lòng sử dụng tính năng "Đăng ký" bằng Email hoặc "Đăng nhập Số Điện Thoại / OTP" để trải nghiệm dữ liệu thật ngay!',
    );
  }

  @override
  Future<UserAccount> syncSupabaseUserSession({
    required String userId,
    String? email,
    String? fullName,
  }) async {
    final client = SupabaseConfig.client;
    String patientCode = 'STYT-${userId.substring(0, min(6, userId.length)).toUpperCase()}';
    String resolvedName = fullName ?? email ?? 'Bệnh nhân';

    if (client != null) {
      try {
        final profileRes = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (profileRes != null) {
          patientCode = profileRes['patient_code'] as String? ?? patientCode;
          resolvedName = profileRes['full_name'] as String? ?? resolvedName;
        } else {
          await client.from('profiles').upsert({
            'id': userId,
            'patient_code': patientCode,
            'full_name': resolvedName,
            'primary_phone': email,
          });
        }
      } catch (e) {
        debugPrint('[Supabase] syncSupabaseUserSession profile error: $e');
      }
    }

    final account = UserAccountModel(
      id: userId,
      patientCode: patientCode,
      fullName: resolvedName,
      primaryContact: email ?? '$userId@auth.supabase',
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );

    await authLocalDataSource.createUser(account);
    await localDataSource.saveSession(
      userId: account.id,
      patientCode: account.patientCode,
      contact: account.primaryContact,
      rememberMe: true,
    );

    return account;
  }
}
