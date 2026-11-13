import 'package:flutter/foundation.dart';
import 'documents_state.dart';

class DocumentsViewModel extends ChangeNotifier {
  DocumentsViewModel()
      : _state = const DocumentsState(
          selectedCategory: DocumentCategory.all,
        );

  DocumentsState _state;
  DocumentsState get state => _state;

  void selectCategory(DocumentCategory category) {
    if (_state.selectedCategory == category) return;
    _state = _state.copyWith(selectedCategory: category);
    notifyListeners();
  }

  void dismissViewerTip() {
    if (!_state.showViewerTip) return;
    _state = _state.copyWith(showViewerTip: false);
    notifyListeners();
  }
}

