import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/config/supabase_config.dart';

abstract class SubscriptionRemoteDataSource {
  Future<bool> purchaseProSubscription(String packageId);
  Future<bool> restorePurchases();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  static const bool _enableIapSandboxDefine =
      bool.fromEnvironment('ENABLE_IAP_SANDBOX', defaultValue: false);

  final bool? shouldSucceed;

  SubscriptionRemoteDataSourceImpl({this.shouldSucceed});

  bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  bool get _isSandboxAllowed =>
      _isFlutterTest || (!kReleaseMode && _enableIapSandboxDefine);

  @override
  Future<bool> purchaseProSubscription(String packageId) async {
    if (shouldSucceed != null) return shouldSucceed!;
    if (_isSandboxAllowed) return true;

    final client = SupabaseConfig.client;
    final currentUser = client?.auth.currentUser;
    if (client == null || currentUser == null) {
      return false;
    }

    try {
      final profile = await client
          .from('profiles')
          .select('is_pro')
          .eq('id', currentUser.id)
          .maybeSingle();
      return profile?['is_pro'] == true;
    } catch (e) {
      debugPrint('[SubscriptionRemoteDataSource] purchaseProSubscription check failed: $e');
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    if (shouldSucceed != null) return shouldSucceed!;
    if (_isFlutterTest) return true;

    final client = SupabaseConfig.client;
    final currentUser = client?.auth.currentUser;
    if (client == null || currentUser == null) {
      return false;
    }

    try {
      final profile = await client
          .from('profiles')
          .select('is_pro')
          .eq('id', currentUser.id)
          .maybeSingle();
      return profile?['is_pro'] == true;
    } catch (e) {
      debugPrint('[SubscriptionRemoteDataSource] restorePurchases failed: $e');
      return false;
    }
  }
}
