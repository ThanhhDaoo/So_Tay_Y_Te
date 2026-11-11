import 'package:flutter/material.dart';
import '../../../../domain/entities/medical_event.dart';
import '../../../../domain/usecases/medical/save_medical_event_usecase.dart';
import 'add_record_state.dart';

class AddRecordViewModel extends ChangeNotifier {
  final SaveMedicalEventUseCase? saveMedicalEventUseCase;

  AddRecordState _state = AddRecordInitial();
  AddRecordState get state => _state;

  AddRecordViewModel({this.saveMedicalEventUseCase});

  Future<void> saveRecord(MedicalEvent event) async {
    _state = AddRecordSubmitting();
    notifyListeners();

    try {
      if (saveMedicalEventUseCase != null) {
        await saveMedicalEventUseCase!(event);
      }
      _state = AddRecordSuccess();
    } catch (e) {
      _state = AddRecordFailure(e.toString());
    }
    notifyListeners();
  }
}
