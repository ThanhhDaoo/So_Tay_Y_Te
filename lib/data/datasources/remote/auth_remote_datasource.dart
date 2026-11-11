import '../../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginAnonymous();
  Future<UserModel> linkAccount({required String email, required String password});
  Future<bool> checkSubscriptionStatus(String userId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> loginAnonymous() async {
    return UserModel(id: 'anon_1', fullName: 'Người dùng tạm');
  }

  @override
  Future<UserModel> linkAccount({required String email, required String password}) async {
    return UserModel(id: 'user_1', fullName: 'Người dùng chính thức');
  }

  @override
  Future<bool> checkSubscriptionStatus(String userId) async {
    return false;
  }
}
