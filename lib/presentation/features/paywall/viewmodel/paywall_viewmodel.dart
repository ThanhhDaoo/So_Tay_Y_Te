import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/local/app_preferences_datasource.dart';
import '../../../../data/datasources/remote/subscription_remote_datasource.dart';
import 'paywall_state.dart';

class PaywallViewModel extends ChangeNotifier {
  final SubscriptionRemoteDataSource _subscriptionDataSource;
  final AppPreferencesDataSource _preferencesDataSource;

  PaywallState _state;
  PaywallState get state => _state;

  PaywallViewModel({
    SubscriptionRemoteDataSource? subscriptionDataSource,
    AppPreferencesDataSource? preferencesDataSource,
    PaywallState? initialState,
  })  : _subscriptionDataSource = subscriptionDataSource ??
            (sl.isRegistered<SubscriptionRemoteDataSource>()
                ? sl<SubscriptionRemoteDataSource>()
                : SubscriptionRemoteDataSourceImpl()),
        _preferencesDataSource = preferencesDataSource ??
            (sl.isRegistered<AppPreferencesDataSource>()
                ? sl<AppPreferencesDataSource>()
                : AppPreferencesDataSourceImpl()),
        _state = initialState ?? const PaywallState() {
    _loadProStatus();
  }

  Future<void> _loadProStatus() async {
    final isPro = await _preferencesDataSource.getProStatus();
    if (isPro != _state.isPro) {
      _state = _state.copyWith(isPro: isPro);
      notifyListeners();
    }
  }

  void selectPlan(PlanType plan) {
    if (_state.selectedPlan == plan) return;
    _state = _state.copyWith(selectedPlan: plan);
    notifyListeners();
  }

  Future<void> linkAccount(String provider) async {
    _state = _state.copyWith(isProcessing: true);
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _state = _state.copyWith(
      isProcessing: false,
      linkedProvider: provider,
      feedbackMessage: 'Đã liên kết tài khoản $provider thành công!',
    );
    notifyListeners();
  }

  Future<bool> subscribeToPlan(PlanType plan) async {
    _state = _state.copyWith(isProcessing: true);
    notifyListeners();

    try {
      final success = await _subscriptionDataSource.purchaseProSubscription(plan.id);
      if (success) {
        await _preferencesDataSource.setProStatus(true);
        _state = _state.copyWith(
          isProcessing: false,
          isPro: true,
          feedbackMessage: 'Kích hoạt thành công ${plan.title}! Toàn bộ tính năng Pro đã được mở khóa.',
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[PaywallViewModel] purchase failed: $e');
    }

    _state = _state.copyWith(
      isProcessing: false,
      feedbackMessage: 'Giao dịch chưa hoàn tất. Vui lòng thử lại.',
    );
    notifyListeners();
    return false;
  }

  Future<bool> restorePurchases() async {
    _state = _state.copyWith(isProcessing: true);
    notifyListeners();

    try {
      final success = await _subscriptionDataSource.restorePurchases();
      if (success) {
        await _preferencesDataSource.setProStatus(true);
        _state = _state.copyWith(
          isProcessing: false,
          isPro: true,
          feedbackMessage: 'Đã khôi phục thành công gói đăng ký Pro!',
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[PaywallViewModel] restore failed: $e');
    }

    _state = _state.copyWith(
      isProcessing: false,
      feedbackMessage: 'Không tìm thấy thông tin đăng ký hợp lệ.',
    );
    notifyListeners();
    return false;
  }

  void clearFeedbackMessage() {
    _state = _state.copyWith(clearFeedbackMessage: true);
    notifyListeners();
  }
}
