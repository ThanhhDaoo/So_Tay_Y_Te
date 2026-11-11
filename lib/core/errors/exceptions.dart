class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Lỗi máy chủ']);
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException([this.message = 'Lỗi truy vấn cơ sở dữ liệu']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Mất kết nối mạng']);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Lỗi xác thực']);
}
