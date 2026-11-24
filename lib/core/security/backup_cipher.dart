import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Tiện ích mã hóa xác thực AES-256-GCM kết hợp dẫn xuất khóa PBKDF2-HMAC-SHA256
/// dùng để bảo vệ tệp sao lưu y tế (.sotayyte) và dữ liệu nhạy cảm.
class BackupCipher {
  static const String envelopeMagic = 'STYT_ENC_V2';
  static const int _pbkdf2Iterations = 20000;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _macBitLength = 128;

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rng.nextInt(256)));
  }

  static Uint8List _deriveKey(String passphrase, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, 32));
    return derivator.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  /// Mã hóa chuỗi JSON thuần sang phong bì JSON chứa ciphertext AES-256-GCM.
  static String encryptJsonPayload(String plainJson, {required String passphrase}) {
    if (passphrase.isEmpty) {
      throw ArgumentError('Passphrase mã hóa không được để trống.');
    }
    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);
    final key = _deriveKey(passphrase, salt);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          _macBitLength,
          nonce,
          Uint8List.fromList(utf8.encode(envelopeMagic)),
        ),
      );

    final plainBytes = Uint8List.fromList(utf8.encode(plainJson));
    final cipherBytes = cipher.process(plainBytes);
    final checksum = sha256.convert(plainBytes).toString();

    return jsonEncode({
      'magic': envelopeMagic,
      'alg': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iter': _pbkdf2Iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(cipherBytes),
      'sha256': checksum,
    });
  }

  /// Giải mã phong bì `.sotayyte` (hỗ trợ cả chuẩn mã hóa AES-256-GCM v2 và JSON v1 cũ).
  static Map<String, dynamic> decryptToMap(
    String rawContent, {
    required String passphrase,
  }) {
    final outer = jsonDecode(rawContent);
    if (outer is! Map<String, dynamic>) {
      throw const FormatException('Định dạng tệp sao lưu không hợp lệ.');
    }

    // Tương thích ngược với tệp v1 chưa mã hóa nếu có
    if (outer['magic'] != envelopeMagic && outer['app'] == 'So_Tay_Y_Te') {
      return outer;
    }

    if (outer['magic'] != envelopeMagic) {
      throw const FormatException('Tệp không phải định dạng sao lưu Sổ Tay Y Tế (.sotayyte).');
    }

    final salt = base64Decode(outer['salt'] as String);
    final nonce = base64Decode(outer['nonce'] as String);
    final cipherBytes = base64Decode(outer['ciphertext'] as String);
    final key = _deriveKey(passphrase, salt);

    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(key),
            _macBitLength,
            nonce,
            Uint8List.fromList(utf8.encode(envelopeMagic)),
          ),
        );

      final plainBytes = cipher.process(cipherBytes);
      final expectedSha = outer['sha256'] as String?;
      if (expectedSha != null && expectedSha.isNotEmpty) {
        final actualSha = sha256.convert(plainBytes).toString();
        if (actualSha != expectedSha) {
          throw const FormatException('Tệp sao lưu đã bị thay đổi hoặc hỏng dữ liệu.');
        }
      }

      final decoded = jsonDecode(utf8.decode(plainBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Nội dung giải mã không hợp lệ.');
      }
      return decoded;
    } on InvalidCipherTextException {
      throw const FormatException('Mật khẩu giải mã không chính xác hoặc tệp sao lưu bị hỏng.');
    }
  }
}
