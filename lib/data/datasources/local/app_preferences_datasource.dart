abstract class AppPreferencesDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> setProStatus(bool isPro);
  Future<bool> getProStatus();
}

class AppPreferencesDataSourceImpl implements AppPreferencesDataSource {
  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<void> setProStatus(bool isPro) async {}

  @override
  Future<bool> getProStatus() async => false;
}
