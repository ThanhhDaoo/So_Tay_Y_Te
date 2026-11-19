import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'emergency_card_state.dart';

/// ViewModel quản lý trạng thái và tương tác cho màn hình Thẻ Cấp Cứu Khẩn Cấp (ICE).
class EmergencyCardViewModel extends ChangeNotifier {
  EmergencyCardState _state = EmergencyCardState.initial();

  EmergencyCardState get state => _state;

  Future<void> loadProfile() async {
    try {
      if (sl.isRegistered<AuthRepository>()) {
        final auth = sl<AuthRepository>();
        final session = await auth.getActiveSession();
        if (session != null) {
          String demographics = session.gender ?? 'Chưa rõ';
          if (session.dateOfBirth != null && session.dateOfBirth!.isNotEmpty) {
            demographics += ' • ${session.dateOfBirth}';
          }
          final hasBlood = session.bloodType != null &&
              session.bloodType!.isNotEmpty &&
              session.bloodType != 'Chưa rõ';

          String heightStr = '-- cm';
          String weightStr = '-- kg';
          String organDonor = 'CHƯA ĐĂNG KÝ';
          EmergencyContactInfo primaryIce = _state.primaryContact;
          DrugAllergyWarning allergyWarn = _state.allergyWarning;
          List<ChronicConditionItem> conditions = _state.chronicConditions;

          final details = await auth.getUserProfileDetails(session.id);
          if (details != null) {
            final h = details['height'] as String?;
            final w = details['weight'] as String?;
            if (h != null && h.trim().isNotEmpty) heightStr = '${h.trim()} cm';
            if (w != null && w.trim().isNotEmpty) weightStr = '${w.trim()} kg';
            if (details['organ_donor'] != null) organDonor = details['organ_donor'] as String;

            final ice = details['emergency_contact'] as String?;
            if (ice != null && ice.trim().isNotEmpty) {
              primaryIce = EmergencyContactInfo(
                label: 'NGƯỜI THÂN KHẨN CẤP (ICE)',
                name: ice.trim(),
                phone: ice.trim(),
              );
            }

            final all = details['allergies'] as String?;
            if (all != null && all.trim().isNotEmpty && all != 'Không có') {
              allergyWarn = DrugAllergyWarning(
                severityBadge: 'CẢNH BÁO',
                title: 'Dị ứng: ${all.trim()}',
                description: 'Cần đặc biệt lưu ý trước khi chỉ định thuốc hoặc can thiệp y tế.',
                isSevere: true,
              );
            }

            final cond = details['chronic_conditions'] as String?;
            if (cond != null && cond.trim().isNotEmpty && cond != 'Không có') {
              final list = cond.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              conditions = list.map((c) => ChronicConditionItem(
                title: c,
                badgeLabel: 'GHI NHẬN',
                note: 'Theo dõi thường quy',
                iconAsset: 'assets/icons/ic_condition_lungs.svg',
              )).toList();
            }
          }

          _state = _state.copyWith(
            primaryContact: primaryIce,
            allergyWarning: allergyWarn,
            chronicConditions: conditions,
            patient: _state.patient.copyWith(
              fullName: session.fullName.isNotEmpty ? session.fullName : 'Chưa cập nhật',
              demographics: demographics,
              bloodType: hasBlood ? session.bloodType! : '--',
              rhFactor: hasBlood ? 'Rh Dương' : 'Chưa rõ',
              height: heightStr,
              weight: weightStr,
              organDonorStatus: organDonor,
              avatarAsset: session.avatarUrl ?? _state.patient.avatarAsset,
            ),
          );
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  /// Bật/tắt hiển thị thẻ ICE trên màn hình khóa.
  void toggleLockScreenWidget() {
    final nextValue = !_state.isLockScreenWidgetEnabled;
    _state = _state.copyWith(
      isLockScreenWidgetEnabled: nextValue,
      lastActionMessage: nextValue
          ? 'Đã bật hiển thị thẻ ICE trên màn hình khóa 24/7'
          : 'Đã tắt hiển thị thẻ ICE trên màn hình khóa',
    );
    notifyListeners();
  }

  /// Chuyển tab trên thanh điều hướng dưới cùng.
  void selectNavIndex(int index) {
    if (_state.selectedNavIndex == index) return;
    _state = _state.copyWith(selectedNavIndex: index);
    notifyListeners();
  }

  /// Kích hoạt gọi người thân khẩn cấp (ICE).
  void callPrimaryContact() {
    final c = _state.primaryContact;
    _state = _state.copyWith(
      lastActionMessage: 'Đang kết nối cuộc gọi tới ${c.name} (${c.phone})...',
    );
    notifyListeners();
  }

  /// Kích hoạt gọi bác sĩ điều trị.
  void callDoctor() {
    final c = _state.doctorContact;
    _state = _state.copyWith(
      lastActionMessage: 'Đang kết nối cuộc gọi tới ${c.name} (${c.phone})...',
    );
    notifyListeners();
  }

  /// Kích hoạt gọi tổng đài cấp cứu 115.
  void callEmergency115() {
    _state = _state.copyWith(
      lastActionMessage: 'Đang gọi Tổng đài Cấp cứu Quốc gia 115...',
    );
    notifyListeners();
  }

  void clearActionMessage() {
    if (_state.lastActionMessage == null) return;
    _state = _state.copyWith(clearActionMessage: true);
    notifyListeners();
  }
}
