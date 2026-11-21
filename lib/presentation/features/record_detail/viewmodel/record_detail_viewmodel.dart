import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/repositories/medical_record_repository.dart';

class RecordDetailViewModel extends ChangeNotifier {
  final MedicalRecordRepository? repository;
  MedicalEvent? _event;
  MedicalEvent? get event => _event;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  RecordDetailViewModel({this.repository});

  Future<void> fetchDetail(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final repo = repository ??
          (sl.isRegistered<MedicalRecordRepository>()
              ? sl<MedicalRecordRepository>()
              : null);
      if (repo != null && id.isNotEmpty) {
        _event = await repo.getMedicalEventById(id);
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
