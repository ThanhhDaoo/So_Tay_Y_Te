/// Tài khoản mẫu dùng để đăng nhập giả lập khi chưa kết nối backend.
class MockAuthAccount {
  final String id;
  final String profileCode;
  final String email;
  final String password;
  final String fullName;

  const MockAuthAccount({
    required this.id,
    required this.profileCode,
    required this.email,
    required this.password,
    required this.fullName,
  });
}

/// Nguồn dữ liệu giả lập cho luồng đăng nhập.
class MockAuthDataSource {
  static const List<MockAuthAccount> demoAccounts = [
    MockAuthAccount(
      id: 'user_trang_01',
      profileCode: 'STYT-892410',
      email: 'nguyenthutrang@sotayyte.vn',
      password: '123456',
      fullName: 'Nguyễn Thu Trang',
    ),
    MockAuthAccount(
      id: 'user_tu_02',
      profileCode: 'STYT-100001',
      email: 'bacsitu@sotayyte.vn',
      password: '123456',
      fullName: 'BS. Trần Minh Tú',
    ),
  ];

  static MockAuthAccount get defaultDemoAccount => demoAccounts.first;

  /// Xác thực Email hoặc Mã hồ sơ và mật khẩu với danh sách tài khoản giả.
  MockAuthAccount? authenticate({
    required String identifier,
    required String password,
  }) {
    final normalized = identifier.trim().toLowerCase();
    for (final account in demoAccounts) {
      final matchesIdentifier =
          account.profileCode.toLowerCase() == normalized ||
          account.email.toLowerCase() == normalized;
      if (matchesIdentifier && account.password == password) {
        return account;
      }
    }
    return null;
  }
}

