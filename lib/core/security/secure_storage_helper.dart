abstract class SecureStorageHelper {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clearAll();
}

class SecureStorageHelperImpl implements SecureStorageHelper {
  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<String?> read(String key) async {
    return null;
  }

  @override
  Future<void> delete(String key) async {}

  @override
  Future<void> clearAll() async {}
}
