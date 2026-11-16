import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../models/user_account_model.dart';

abstract class SupabaseAuthRemoteDataSource {
  Future<UserAccountModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
  });

  Future<UserAccountModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPhoneOtp({required String phone});
  Future<UserAccountModel> verifyPhoneOtp({
    required String phone,
    required String token,
  });

  Future<void> signInWithOAuth(OAuthProvider provider);
  Future<UserAccountModel> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
  });

  Future<UserAccountModel> signInAnonymously();
  Future<void> resetPassword(String email);
  Future<void> signOut();
  User? get currentAuthUser;
}

class SupabaseAuthRemoteDataSourceImpl implements SupabaseAuthRemoteDataSource {
  SupabaseClient? get _client => SupabaseConfig.client;

  @override
  User? get currentAuthUser => _client?.auth.currentUser;

  @override
  Future<UserAccountModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? dateOfBirth,
    String? gender,
    String? bloodType,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình URL hoặc Anon Key.');
    }

    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender ?? 'Chưa rõ',
        'blood_type': bloodType ?? 'Chưa rõ',
      },
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Không thể tạo tài khoản trên máy chủ Supabase.');
    }

    // Tra cứu hoặc tạo mới bản ghi trong public.profiles
    final profileRes = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final generatedCode = 'STYT-${Random().nextInt(899999) + 100000}';
    final patientCode = profileRes != null
        ? (profileRes['patient_code'] as String? ?? generatedCode)
        : generatedCode;

    if (profileRes == null) {
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'patient_code': patientCode,
          'full_name': fullName,
          'date_of_birth': dateOfBirth,
          'gender': gender ?? 'Chưa rõ',
          'blood_type': bloodType ?? 'Chưa rõ',
          'primary_phone': email,
        });
      } catch (e) {
        debugPrint('[Supabase] Không thể chèn profile: $e');
      }
    }

    return UserAccountModel(
      id: user.id,
      patientCode: patientCode,
      fullName: fullName,
      primaryContact: email,
      passwordHash: '',
      salt: '',
      dateOfBirth: dateOfBirth,
      gender: gender,
      bloodType: bloodType,
      createdAt: DateTime.now(),
    );
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
      email: email,
      password: password,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Đăng nhập thất bại.');
    }

    final profileRes = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final fullName = profileRes != null
        ? (profileRes['full_name'] as String? ?? user.email ?? 'Bệnh nhân')
        : (user.userMetadata?['full_name'] as String? ?? user.email ?? 'Bệnh nhân');

    final patientCode = profileRes != null
        ? (profileRes['patient_code'] as String? ?? 'STYT-892410')
        : 'STYT-892410';

    return UserAccountModel(
      id: user.id,
      patientCode: patientCode,
      fullName: fullName,
      primaryContact: user.email ?? email,
      passwordHash: '',
      salt: '',
      dateOfBirth: profileRes?['date_of_birth'] as String?,
      gender: profileRes?['gender'] as String?,
      bloodType: profileRes?['blood_type'] as String?,
      createdAt: DateTime.now(),
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
      token: token,
      type: OtpType.sms,
    );

    final user = res.user;
    if (user == null) {
      throw Exception('Mã OTP xác thực Supabase không hợp lệ.');
    }

    final profileRes = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final patientCode = profileRes != null
        ? (profileRes['patient_code'] as String? ?? 'STYT-892410')
        : 'STYT-892410';

    return UserAccountModel(
      id: user.id,
      patientCode: patientCode,
      fullName: 'Bệnh nhân ($phone)',
      primaryContact: phone,
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    await client.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.sotayyte://login-callback/',
    );
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

    final profileRes = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final patientCode = profileRes != null
        ? (profileRes['patient_code'] as String? ?? 'STYT-892410')
        : 'STYT-892410';

    return UserAccountModel(
      id: user.id,
      patientCode: patientCode,
      fullName: user.userMetadata?['full_name'] as String? ?? user.email ?? 'Bệnh nhân',
      primaryContact: user.email ?? user.id,
      passwordHash: '',
      salt: '',
      createdAt: DateTime.now(),
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

    return UserAccountModel(
      id: user.id,
      patientCode: 'STYT-GUEST',
      fullName: 'Bệnh nhân Khách',
      primaryContact: 'guest@sotayyte.local',
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

    await client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> signOut() async {
    final client = _client;
    await client?.auth.signOut();
  }
}
