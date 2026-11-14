import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricHardwareType {
  face,
  fingerprint,
  iris,
  none,
}

abstract class BiometricService {
  Future<bool> isBiometricAvailable();
  Future<List<BiometricHardwareType>> getAvailableBiometrics();
  Future<bool> authenticate({required String localizedReason});
}

class BiometricServiceImpl implements BiometricService {
  final LocalAuthentication _localAuth;

  BiometricServiceImpl({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  @override
  Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException catch (e) {
      debugPrint('BiometricService.isBiometricAvailable error: $e');
      return false;
    }
  }

  @override
  Future<List<BiometricHardwareType>> getAvailableBiometrics() async {
    try {
      final types = await _localAuth.getAvailableBiometrics();
      final result = <BiometricHardwareType>[];

      for (final type in types) {
        if (type == BiometricType.face) {
          result.add(BiometricHardwareType.face);
        } else if (type == BiometricType.fingerprint ||
            type == BiometricType.strong ||
            type == BiometricType.weak) {
          result.add(BiometricHardwareType.fingerprint);
        } else if (type == BiometricType.iris) {
          result.add(BiometricHardwareType.iris);
        }
      }

      if (result.isEmpty) {
        result.add(BiometricHardwareType.none);
      }
      return result;
    } on PlatformException catch (e) {
      debugPrint('BiometricService.getAvailableBiometrics error: $e');
      return [BiometricHardwareType.none];
    }
  }

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricService.authenticate error: $e');
      return false;
    }
  }
}
