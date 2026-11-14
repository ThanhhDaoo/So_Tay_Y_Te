import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  /// Sinh chuỗi salt ngẫu nhiên an toàn bằng Cryptographically Secure RNG
  static String generateSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Băm mật khẩu sử dụng SHA-256 kết hợp với Salt
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password::$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Xác thực mật khẩu nhập vào so với chuỗi băm lưu trong CSDL
  static bool verifyPassword({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    final computedHash = hashPassword(password, salt);
    return computedHash == expectedHash;
  }
}

