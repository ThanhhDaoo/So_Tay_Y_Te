enum AuthProviderType {
  emailPassword('password'),
  phoneOtp('phone'),
  google('google'),
  apple('apple'),
  guest('guest');

  final String rawValue;
  const AuthProviderType(this.rawValue);

  static AuthProviderType fromRaw(String value) {
    return AuthProviderType.values.firstWhere(
      (e) => e.rawValue == value,
      orElse: () => AuthProviderType.emailPassword,
    );
  }
}

class AuthIdentity {
  final String id;
  final String userId;
  final AuthProviderType provider;
  final String providerUid;
  final String? emailAssociated;
  final DateTime linkedAt;

  const AuthIdentity({
    required this.id,
    required this.userId,
    required this.provider,
    required this.providerUid,
    this.emailAssociated,
    required this.linkedAt,
  });
}
