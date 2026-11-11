abstract class SubscriptionRemoteDataSource {
  Future<bool> purchaseProSubscription(String packageId);
  Future<bool> restorePurchases();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  @override
  Future<bool> purchaseProSubscription(String packageId) async {
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    return true;
  }
}
