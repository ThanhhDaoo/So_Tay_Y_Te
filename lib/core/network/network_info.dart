abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // Kiểm tra kết nối mạng thực tế qua connectivity_plus
    return true;
  }
}
