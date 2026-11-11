import 'package:flutter/material.dart';

class PaywallViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> purchasePro() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
