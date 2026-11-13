import 'package:flutter/foundation.dart';
import 'paywall_state.dart';

class PaywallViewModel extends ChangeNotifier {
  PaywallViewModel() : _state = const PaywallState();

  PaywallState _state;
  PaywallState get state => _state;

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
    );
    notifyListeners();
  }
}
