import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/utils/input_validators.dart';
import '../../models/user_account_model.dart';

class AuthAccountAlreadyExistsException implements Exception {
  final String message;
  const AuthAccountAlreadyExistsException([
    this.message = 'Số điện thoại hoặc Email này đã được đăng ký hồ sơ.',
  ]);

  @override
  String toString() => message;
}

class AuthEmailConfirmationRequiredException implements Exception {
  final String email;
  final UserAccountModel pendingAccount;
  const AuthEmailConfirmationRequiredException({
    required this.email,
    required this.pendingAccount,
  });

  @override
  String toString() =>
      'Vui lòng nhập mã xác thực 6 chữ số đã gửi tới hộp thư $email.';
}

abstract class SupabaseAuthRemoteDataSource {
  Future<UserAccountModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? primaryContact,
    String? patientCode,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
  });

  Future<UserAccountModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendEmailOtp({
    required String email,
    bool shouldCreateUser = false,
  });

  Future<UserAccountModel> verifyEmailOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  });

  Future<void> sendPhoneOtp({required String phone});
  Future<UserAccountModel> verifyPhoneOtp({
    required String phone,
    required String token,
  });

  Future<String?> lookupContactByPatientCode(String patientCode);

  Future<void> signInWithOAuth(OAuthProvider provider);
  Future<UserAccountModel> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
  });

  Future<UserAccountModel> signInAnonymously();
  Future<void> resetPassword(String email);
  Future<void> updateCloudPassword(String newPassword);
  Future<void> updateCloudUserMetadata(Map<String, dynamic> metadata);
  Future<void> signOut();
  User? get currentAuthUser;
}

class SupabaseAuthRemoteDataSourceImpl implements SupabaseAuthRemoteDataSource {
  SupabaseClient? get _client => SupabaseConfig.client;

  @override
  User? get currentAuthUser => _client?.auth.currentUser;

  /// Sinh mã hồ sơ STYT-XXXXXX nhất quán từ UUID người dùng khi chưa có sẵn
  static String derivePatientCodeFromUserId(String userId) {
    final hash = userId.codeUnits.fold<int>(
      17,
      (prev, elem) => (prev * 31 + elem) & 0x7fffffff,
    );
    final sixDigits = 100000 + (hash % 900000);
    return 'STYT-$sixDigits';
  }

  String _resolvePatientCode(
    User user,
    Map<String, dynamic>? profileRes, {
    String? preferredCode,
  }) {
    final fromProfile = profileRes?['patient_code'] as String?;
    if (fromProfile != null && fromProfile.trim().isNotEmpty) {
      return fromProfile.trim().toUpperCase();
    }
    final fromMeta = user.userMetadata?['patient_code'] as String?;
    if (fromMeta != null && fromMeta.trim().isNotEmpty) {
      return fromMeta.trim().toUpperCase();
    }
    if (preferredCode != null && preferredCode.trim().isNotEmpty) {
      return preferredCode.trim().toUpperCase();
    }
    return derivePatientCodeFromUserId(user.id);
  }

  @override
  Future<UserAccountModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? primaryContact,
    String? patientCode,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình URL hoặc Anon Key.');
    }

    final cleanContact = (primaryContact ?? email).trim();
    final provisionalCode =
        (patientCode != null && patientCode.trim().isNotEmpty)
            ? patientCode.trim().toUpperCase()
            : null;

    AuthResponse res;
    try {
      res = await client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'primary_contact': cleanContact,
          'patient_code': ?provisionalCode,
          'date_of_birth': dateOfBirth,
          'gender': gender ?? 'Chưa rõ',
          'blood_type': bloodType ?? 'Chưa rõ',
        },
      );
    } on AuthException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('already registered') ||
          lower.contains('already been registered') ||
          lower.contains('user_already_exists')) {
        throw const AuthAccountAlreadyExistsException();
      }
      if (lower.contains('rate limit') || lower.contains('over_email_send_rate_limit')) {
        throw Exception(
          'Hệ thống gửi xác thực quá giới hạn tạm thời. Vui lòng đợi ít phút rồi thử lại.',
        );
      }
      throw Exception('Đăng ký thất bại: ${e.message}');
    }

    final user = res.user;
    if (user == null) {
      throw Exception('Không thể tạo tài khoản trên máy chủ Supabase.');
    }

    // Khi Supabase bật Confirm Email, nếu email đã tồn tại sẽ trả về identities rỗng
    if (user.identities != null && user.identities!.isEmpty) {
      throw const AuthAccountAlreadyExistsException();
    }

    Map<String, dynamic>? profileRes;
    if (res.session != null) {
      try {
        profileRes = await client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {}
    }

    final finalPatientCode = _resolvePatientCode(
      user,
      profileRes,
      preferredCode: provisionalCode,
    );

    // Đồng bộ patient_code vào user_metadata và public.profiles nếu đã có phiên
    if (res.session != null) {
      if (user.userMetadata?['patient_code'] != finalPatientCode) {
        try {
          await client.auth.updateUser(
            UserAttributes(data: {'patient_code': finalPatientCode}),
          );
        } catch (_) {}
      }

      if (profileRes == null) {
        try {
          await client.from('profiles').upsert({
            'id': user.id,
            'patient_code': finalPatientCode,
            'full_name': fullName.trim(),
            'date_of_birth': dateOfBirth,
            'gender': gender ?? 'Chưa rõ',
            'blood_type': bloodType ?? 'Chưa rõ',
            'primary_phone': cleanContact,
          });
        } catch (e) {
          debugPrint('[Supabase] Bỏ qua ghi bảng profiles (có thể chưa tạo bảng): $e');
        }
      }
    }

    final accountModel = UserAccountModel(
      id: user.id,
      patientCode: finalPatientCode,
      fullName: fullName.trim(),
      primaryContact: cleanContact,
      passwordHash: '',
      salt: '',
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodType: bloodType,
      createdAt: DateTime.now(),
    );

    // Nếu dự án Supabase bật Confirm Email (res.session == null) đối với email thật
    final isSyntheticPhoneEmail = email.endsWith('@sotayyte.vn');
    if (res.session == null && !isSyntheticPhoneEmail) {
      throw AuthEmailConfirmationRequiredException(
        email: email.trim().toLowerCase(),
        pendingAccount: accountModel,
      );
    }

    return accountModel;
  }

  @override
  Future<UserAccountModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình URL hoặc Anon Key.');
    }

    final res = await client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Đăng nhập thất bại.');
    }

    return await _buildAccountFromSupabaseUser(
      client,
      user,
      fallbackContact: email.trim().toLowerCase(),
    );
  }

  @override
  Future<void> sendEmailOtp({
    required String email,
    bool shouldCreateUser = false,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    await client.auth.signInWithOtp(
      email: email.trim().toLowerCase(),
      shouldCreateUser: shouldCreateUser,
    );
  }

  @override
  Future<UserAccountModel> verifyEmailOtp({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    final res = await client.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: token.trim(),
      type: type,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Mã xác thực Email OTP không hợp lệ hoặc đã hết hạn.');
    }

    return await _buildAccountFromSupabaseUser(
      client,
      user,
      fallbackContact: email.trim().toLowerCase(),
    );
  }

  @override
  Future<void> sendPhoneOtp({required String phone}) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    await client.auth.signInWithOtp(
      phone: phone,
    );
  }

  @override
  Future<UserAccountModel> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    final res = await client.auth.verifyOTP(
      phone: phone,
      token: token.trim(),
      type: OtpType.sms,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Mã OTP xác thực không hợp lệ hoặc đã hết hạn.');
    }

    final localPhone = InputValidators.normalizePhoneLocal(phone);
    return await _buildAccountFromSupabaseUser(
      client,
      user,
      fallbackContact: localPhone,
    );
  }

  @override
  Future<String?> lookupContactByPatientCode(String patientCode) async {
    final client = _client;
    if (client == null) return null;

    try {
      final profileRes = await client
          .from('profiles')
          .select('primary_phone')
          .ilike('patient_code', patientCode.trim())
          .maybeSingle();

      final contact = profileRes?['primary_phone'] as String?;
      if (contact != null && contact.trim().isNotEmpty) {
        return contact.trim();
      }
    } catch (_) {}
    return null;
  }

  /// Kiểm tra nhanh trên Supabase Auth Settings xem OAuth Provider đã được bật chưa
  Future<bool> _isOAuthProviderEnabledOnCloud(OAuthProvider provider) async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }

    final httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 3);
    try {
      final uri = Uri.parse('${SupabaseConfig.supabaseUrl}/auth/v1/settings');
      final req = await httpClient.getUrl(uri);
      req.headers.set('apikey', SupabaseConfig.supabaseAnonKey);
      final resp = await req.close().timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final body = await resp.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final external = data['external'] as Map<String, dynamic>?;
        if (external != null) {
          final key = provider == OAuthProvider.apple ? 'apple' : 'google';
          return external[key] == true;
        }
      }
    } catch (_) {
      // Nếu mạng chậm hoặc không đọc được settings, cho phép thử mở trình duyệt bình thường
      return true;
    } finally {
      httpClient.close(force: true);
    }
    return true;
  }

  @override
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    final providerLabel = provider == OAuthProvider.apple ? 'Apple ID' : 'Google';
    final isEnabled = await _isOAuthProviderEnabledOnCloud(provider);
    if (!isEnabled) {
      throw Exception(
        'Đăng nhập bằng $providerLabel chưa được bật trên Supabase Console (Authentication -> Providers -> $providerLabel).\n'
        'Vui lòng bật Provider này trên Dashboard hoặc đăng nhập bằng Số điện thoại / Email.',
      );
    }

    final launched = await client.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.sotayyte://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw Exception(
        'Không thể mở trình duyệt xác thực $providerLabel. Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<UserAccountModel> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    final res = await client.auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Đăng nhập qua OAuth thất bại.');
    }

    return await _buildAccountFromSupabaseUser(
      client,
      user,
      fallbackContact: user.email ?? user.id,
    );
  }

  @override
  Future<UserAccountModel> signInAnonymously() async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    final res = await client.auth.signInAnonymously();
    final user = res.user;
    if (user == null) {
      throw Exception('Không thể tạo phiên ẩn danh.');
    }

    final guestCode = derivePatientCodeFromUserId(user.id);
    return UserAccountModel(
      id: user.id,
      patientCode: guestCode,
      fullName: 'Khách (Chưa đăng ký)',
      primaryContact: 'guest_${user.id.substring(0, 8)}@sotayyte.local',
      passwordHash: '',
      salt: '',
      isGuest: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    await client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: 'io.supabase.sotayyte://login-callback/',
    );
  }

  @override
  Future<void> updateCloudPassword(String newPassword) async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) return;
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> updateCloudUserMetadata(Map<String, dynamic> metadata) async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) return;
    await client.auth.updateUser(UserAttributes(data: metadata));
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    await client?.auth.signOut();
  }

  Future<UserAccountModel> _buildAccountFromSupabaseUser(
    SupabaseClient client,
    User user, {
    required String fallbackContact,
  }) async {
    Map<String, dynamic>? profileRes;
    try {
      profileRes = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {}

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final patientCode = _resolvePatientCode(user, profileRes);

    // Chuẩn hóa liên hệ gốc (nếu là email giả lập SĐT 849xxx@sotayyte.vn thì trả lại SĐT 09xxx)
    String resolvedContact = (profileRes?['primary_phone'] as String?) ??
        (meta['primary_contact'] as String?) ??
        user.email ??
        user.phone ??
        fallbackContact;
    if (resolvedContact.endsWith('@sotayyte.vn')) {
      final phonePrefix = resolvedContact.split('@').first;
      if (RegExp(r'^[0-9]+$').hasMatch(phonePrefix)) {
        resolvedContact = InputValidators.normalizePhoneLocal(phonePrefix);
      }
    }

    final fullName = (profileRes?['full_name'] as String?) ??
        (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        (user.email != null && !user.email!.endsWith('@sotayyte.vn')
            ? user.email!.split('@').first
            : 'Chủ hồ sơ ($resolvedContact)');

    final dob = (profileRes?['date_of_birth'] as String?) ??
        (meta['date_of_birth'] as String?);
    final gender = (profileRes?['gender'] as String?) ??
        (meta['gender'] as String?);
    final bloodType = (profileRes?['blood_type'] as String?) ??
        (meta['blood_type'] as String?);
    final avatarUrl = (meta['avatar_url'] as String?) ??
        (meta['picture'] as String?);

    // Nếu user_metadata chưa lưu patient_code (VD: lần đầu đăng nhập Google/Apple), lưu lại để cố định mãi mãi
    if (meta['patient_code'] == null) {
      try {
        await client.auth.updateUser(
          UserAttributes(data: {'patient_code': patientCode}),
        );
      } catch (_) {}
    }

    return UserAccountModel(
      id: user.id,
      patientCode: patientCode,
      fullName: fullName,
      primaryContact: resolvedContact,
      passwordHash: '',
      salt: '',
      dateOfBirth: dob,
      gender: gender,
      bloodType: bloodType,
      avatarUrl: avatarUrl,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }
}
