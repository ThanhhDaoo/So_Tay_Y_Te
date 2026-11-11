abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Lỗi kết nối máy chủ']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Lỗi cơ sở dữ liệu nội bộ']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Lỗi lưu trữ dữ liệu tạm']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Không có kết nối mạng internet']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Xác thực không thành công']);
}
