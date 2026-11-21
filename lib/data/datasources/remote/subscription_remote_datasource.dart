abstract class SubscriptionRemoteDataSource {
  Future<bool> purchaseProSubscription(String packageId);
  Future<bool> restorePurchases();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final bool shouldSucceed;

  SubscriptionRemoteDataSourceImpl({this.shouldSucceed = true});

  @override
  Future<bool> purchaseProSubscription(String packageId) async {
    return shouldSucceed;
  }

  @override
  Future<bool> restorePurchases() async {
    return shouldSucceed;
  }
}
