import 'package:flutter/material.dart';
import '../../../../domain/usecases/medical/get_medical_timeline_usecase.dart';
import 'timeline_state.dart';

class TimelineViewModel extends ChangeNotifier {
  final GetMedicalTimelineUseCase? getTimelineUseCase;

  TimelineState _state = TimelineInitial();
  TimelineState get state => _state;

  TimelineViewModel({this.getTimelineUseCase});

  Future<void> loadEvents() async {
    _state = TimelineLoading();
    notifyListeners();

    try {
      if (getTimelineUseCase != null) {
        final events = await getTimelineUseCase!();
        _state = TimelineLoaded(events);
      } else {
        _state = const TimelineLoaded([]);
      }
    } catch (e) {
      _state = TimelineError(e.toString());
    }
    notifyListeners();
  }
}
