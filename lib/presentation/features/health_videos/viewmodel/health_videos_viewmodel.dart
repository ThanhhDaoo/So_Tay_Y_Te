import 'package:flutter/foundation.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../data/datasources/local/elder_care_local_datasource.dart';
import '../../../../data/repositories/elder_care_repository_impl.dart';
import '../../../../domain/entities/health_video.dart';
import '../../../../domain/repositories/elder_care_repository.dart';

class HealthVideosViewModel extends ChangeNotifier {
  static const List<String> categories = [
    'Tất cả',
    'Tim mạch & Huyết áp',
    'Xương khớp',
    'Dưỡng sinh & Hơi thở',
    'Giấc ngủ',
  ];

  final ElderCareRepository? _customRepo;
  List<HealthVideo> _videos = const [];
  String _selectedCategory = 'Tất cả';
  bool _isLoading = true;

  List<HealthVideo> get videos => _videos;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  HealthVideosViewModel({ElderCareRepository? repository})
      : _customRepo = repository {
    loadVideos();
  }

  ElderCareRepository? _resolveRepo() {
    if (_customRepo != null) return _customRepo;
    if (sl.isRegistered<ElderCareRepository>()) {
      return sl<ElderCareRepository>();
    }
    if (sl.isRegistered<DatabaseHelper>()) {
      return ElderCareRepositoryImpl(
        localDataSource:
            ElderCareLocalDataSourceImpl(databaseHelper: sl<DatabaseHelper>()),
      );
    }
    return null;
  }

  Future<void> loadVideos() async {
    _isLoading = true;
    notifyListeners();
    try {
      final repo = _resolveRepo();
      if (repo != null) {
        _videos = await repo.getHealthVideos(category: _selectedCategory);
      }
    } catch (e) {
      debugPrint('[HealthVideosViewModel] loadVideos error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectCategory(String category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    await loadVideos();
  }

  Future<void> toggleSave(HealthVideo video) async {
    final repo = _resolveRepo();
    if (repo == null) return;
    await repo.toggleSaveVideo(video.id, !video.isSaved);
    await loadVideos();
  }

  Future<void> recordWatched(HealthVideo video) async {
    final repo = _resolveRepo();
    await repo?.markVideoWatched(video.id);
    await loadVideos();
  }
}
