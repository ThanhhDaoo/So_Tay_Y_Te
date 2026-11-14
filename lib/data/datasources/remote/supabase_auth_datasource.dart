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

  Future<void> signInWithOAuth(OAuthProvider provider);
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

    // Đợi trigger tạo profile hoặc lấy thông tin profile
    final profileRes = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final patientCode = profileRes != null
        ? (profileRes['patient_code'] as String? ?? 'STYT-999999')
        : 'STYT-999999';

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
