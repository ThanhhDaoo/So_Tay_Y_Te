import 'package:flutter/material.dart';
import '../../../../domain/entities/medical_event.dart';

class RecordDetailViewModel extends ChangeNotifier {
  MedicalEvent? _event;
  MedicalEvent? get event => _event;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchDetail(String id) async {
    _isLoading = true;
    notifyListeners();

    // Giả lập load chi tiết
    await Future.delayed(const Duration(milliseconds: 300));
    _event = MedicalEvent(
      id: id,
      title: 'Chi tiết hồ sơ y tế #$id',
      description: 'Thông tin đầy đủ về đợt khám và đơn thuốc liên quan.',
      date: DateTime.now(),
      type: MedicalEventType.generalCheckup,
    );
    _isLoading = false;
    notifyListeners();
  }
}
