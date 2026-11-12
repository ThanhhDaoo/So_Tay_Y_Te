import 'package:flutter/material.dart';
import 'timeline_state.dart';

/// ViewModel quản lý trạng thái tìm kiếm, lọc và tương tác trên Dòng Thời Gian Bệnh Án.
class TimelineViewModel extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();
  TimelineState _state = TimelineState.initial();

  TimelineState get state => _state;

  void updateSearchQuery(String query) {
    _state = _state.copyWith(searchQuery: query);
    notifyListeners();
  }

  void selectFilter(String filterId) {
    if (_state.selectedFilterId == filterId) return;
    _state = _state.copyWith(selectedFilterId: filterId);
    notifyListeners();
  }

  void notifyUser(String message) {
    _state = _state.copyWith(lastActionMessage: message);
    notifyListeners();
  }

  void clearActionMessage() {
    if (_state.lastActionMessage == null) return;
    _state = _state.copyWith(clearActionMessage: true);
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
