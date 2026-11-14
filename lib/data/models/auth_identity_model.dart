import '../../domain/entities/auth_identity.dart';

class AuthIdentityModel extends AuthIdentity {
  const AuthIdentityModel({
    required super.id,
    required super.userId,
    required super.provider,
    required super.providerUid,
    super.emailAssociated,
    required super.linkedAt,
  });

  factory AuthIdentityModel.fromMap(Map<String, dynamic> map) {
    return AuthIdentityModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      provider: AuthProviderType.fromRaw(map['provider'] as String),
      providerUid: map['provider_uid'] as String,
      emailAssociated: map['email_associated'] as String?,
      linkedAt: DateTime.parse(map['linked_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'provider': provider.rawValue,
      'provider_uid': providerUid,
      'email_associated': emailAssociated,
      'linked_at': linkedAt.toIso8601String(),
    };
  }

  factory AuthIdentityModel.fromEntity(AuthIdentity entity) {
    return AuthIdentityModel(
      id: entity.id,
      userId: entity.userId,
      provider: entity.provider,
      providerUid: entity.providerUid,
      emailAssociated: entity.emailAssociated,
      linkedAt: entity.linkedAt,
    );
  }
}

