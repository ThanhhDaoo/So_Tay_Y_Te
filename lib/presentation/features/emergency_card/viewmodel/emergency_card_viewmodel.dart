import 'package:flutter/material.dart';
import '../../../../domain/entities/user_profile.dart';

class EmergencyCardViewModel extends ChangeNotifier {
  UserProfile? _profile;
  UserProfile? get profile => _profile;

  void loadProfile() {
    _profile = const UserProfile(
      id: 'user_default',
      fullName: 'Nguyễn Văn A',
      bloodType: 'O+',
      allergies: ['Penicillin', 'Hải sản'],
      chronicConditions: ['Tiểu đường type 2'],
      emergencyContact: '0901234567 (Vợ)',
    );
    notifyListeners();
  }
}
