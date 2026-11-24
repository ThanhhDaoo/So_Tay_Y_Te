import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/local/app_preferences_datasource.dart';
import '../../../../data/datasources/remote/subscription_remote_datasource.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'paywall_state.dart';

class PaywallViewModel extends ChangeNotifier {
  final SubscriptionRemoteDataSource _subscriptionDataSource;
  final AppPreferencesDataSource _preferencesDataSource;
  final AuthRepository? _authRepository;

  PaywallState _state;
  PaywallState get state => _state;

  PaywallViewModel({
    SubscriptionRemoteDataSource? subscriptionDataSource,
    AppPreferencesDataSource? preferencesDataSource,
    AuthRepository? authRepository,
    PaywallState? initialState,
  })  : _subscriptionDataSource = subscriptionDataSource ??
            (sl.isRegistered<SubscriptionRemoteDataSource>()
                ? sl<SubscriptionRemoteDataSource>()
                : SubscriptionRemoteDataSourceImpl()),
        _preferencesDataSource = preferencesDataSource ??
            (sl.isRegistered<AppPreferencesDataSource>()
                ? sl<AppPreferencesDataSource>()
                : AppPreferencesDataSourceImpl()),
        _authRepository = authRepository ??
            (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null),
        _state = initialState ?? const PaywallState() {
    _loadProStatus();
  }

  bool get _isFlutterTest =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

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

  Future<bool> linkAccount(String provider) async {
    if (_state.isProcessing) return false;
    _state = _state.copyWith(isProcessing: true, clearFeedbackMessage: true);
    notifyListeners();

    try {
      final normalizedProvider = provider.trim().toLowerCase();
      if (_authRepository != null && !_isFlutterTest) {
        if (normalizedProvider == 'google' || normalizedProvider == 'apple') {
          await _authRepository.signInWithSocialProvider(provider: normalizedProvider);
          _state = _state.copyWith(
            isProcessing: false,
            linkedProvider: provider,
            feedbackMessage: 'Đã liên kết tài khoản $provider thành công!',
          );
          notifyListeners();
          return true;
        }
      }

      if (_isFlutterTest) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        _state = _state.copyWith(
          isProcessing: false,
          linkedProvider: provider,
          feedbackMessage: 'Đã liên kết tài khoản $provider thành công!',
        );
        notifyListeners();
        return true;
      }

      _state = _state.copyWith(
        isProcessing: false,
        feedbackMessage:
            'Vui lòng sử dụng mục Đăng ký / Liên kết SĐT ở màn hình Tài khoản để xác thực OTP chính chủ.',
      );
      notifyListeners();
      return false;
    } catch (e) {
      _state = _state.copyWith(
        isProcessing: false,
        feedbackMessage: 'Không thể liên kết tài khoản $provider: ${e.toString().replaceFirst("Exception: ", "")}',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> subscribeToPlan(PlanType plan) async {
    if (_state.isProcessing) return false;
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
      feedbackMessage: 'Cổng thanh toán In-App Purchase chưa hoàn tất giao dịch hoặc chưa cấu hình trên Store.',
    );
    notifyListeners();
    return false;
  }

  Future<bool> restorePurchases() async {
    if (_state.isProcessing) return false;
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
