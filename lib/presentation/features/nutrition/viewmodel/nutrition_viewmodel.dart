import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/user_session_manager.dart';
import '../../../../data/datasources/local/elder_care_local_datasource.dart';
import '../../../../data/repositories/elder_care_repository_impl.dart';
import '../../../../domain/entities/nutrition_item.dart';
import '../../../../domain/repositories/elder_care_repository.dart';

class NutritionViewModel extends ChangeNotifier {
  static const List<String> healthTags = [
    'Tất cả',
    'Huyết áp & Tim mạch',
    'Xương khớp',
    'Đường huyết',
  ];

  final ElderCareRepository? _customRepo;
  final Uuid _uuid = const Uuid();

  List<NutritionGuideline> _guidelines = const [];
  List<DietarySupplement> _supplements = const [];
  String _selectedHealthTag = 'Tất cả';
  bool _isLoading = true;
  String? _feedbackMessage;

  List<NutritionGuideline> get shouldEatList =>
      _guidelines.where((g) => g.isShouldEat).toList();

  List<NutritionGuideline> get shouldAvoidList =>
      _guidelines.where((g) => !g.isShouldEat).toList();

  List<DietarySupplement> get supplements => _supplements;
  String get selectedHealthTag => _selectedHealthTag;
  bool get isLoading => _isLoading;
  String? get feedbackMessage => _feedbackMessage;

  NutritionViewModel({ElderCareRepository? repository})
      : _customRepo = repository {
    loadData();
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

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final repo = _resolveRepo();
      if (repo != null) {
        final mid = AppSessionNotifier.instance.activeMemberId;
        _guidelines = await repo.getNutritionGuidelines(
          memberId: mid,
          healthTag: _selectedHealthTag,
        );
        _supplements = await repo.getSupplements(memberId: mid);
      }
    } catch (e) {
      debugPrint('[NutritionViewModel] loadData error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectHealthTag(String tag) async {
    if (_selectedHealthTag == tag) return;
    _selectedHealthTag = tag;
    await loadData();
  }

  Future<void> addCustomNutritionNote({
    required bool isShouldEat,
    required String foodName,
    required String amount,
    required String reason,
  }) async {
    final repo = _resolveRepo();
    if (repo == null) return;
    final item = NutritionGuideline(
      id: 'nut_${_uuid.v4()}',
      memberId: AppSessionNotifier.instance.activeMemberId,
      type: isShouldEat
          ? NutritionRuleType.shouldEat
          : NutritionRuleType.shouldAvoid,
      healthTag: _selectedHealthTag == 'Tất cả'
          ? 'Huyết áp & Tim mạch'
          : _selectedHealthTag,
      foodName: foodName.trim(),
      recommendedAmount: amount.trim(),
      benefitOrRisk: reason.trim(),
      createdAt: DateTime.now(),
    );
    await repo.saveNutritionGuideline(item);
    await loadData();
    _feedbackMessage = 'Đã lưu thêm ghi chú dinh dưỡng mới!';
    notifyListeners();
  }

  Future<void> addOrUpdateSupplement({
    String? existingId,
    required String productName,
    required String category,
    required String benefits,
    required String dosageGuide,
    required SupplementUsageStatus status,
    String? cautionNote,
    String? imagePath,
  }) async {
    final repo = _resolveRepo();
    if (repo == null) return;
    final item = DietarySupplement(
      id: existingId ?? 'sup_${_uuid.v4()}',
      memberId: AppSessionNotifier.instance.activeMemberId,
      productName: productName.trim(),
      category: category.trim(),
      imagePath: imagePath,
      benefits: benefits.trim(),
      dosageGuide: dosageGuide.trim(),
      usageStatus: status,
      cautionNote: cautionNote?.trim(),
      createdAt: DateTime.now(),
    );
    await repo.saveSupplement(item);
    await loadData();
    _feedbackMessage =
        'Đã lưu thực phẩm chức năng "${item.productName}" thành công!';
    notifyListeners();
  }

  Future<void> toggleSupplementStatus(DietarySupplement item) async {
    final repo = _resolveRepo();
    if (repo == null) return;
    final nextStatus = item.isUsingNow
        ? SupplementUsageStatus.reference
        : SupplementUsageStatus.usingNow;
    await repo.saveSupplement(item.copyWith(usageStatus: nextStatus));
    await loadData();
    _feedbackMessage = nextStatus == SupplementUsageStatus.usingNow
        ? 'Đã chuyển "${item.productName}" sang nhóm Đang dùng.'
        : 'Đã chuyển "${item.productName}" sang nhóm Tham khảo.';
    notifyListeners();
  }

  Future<void> deleteSupplement(DietarySupplement item) async {
    final repo = _resolveRepo();
    if (repo == null) return;
    await repo.deleteSupplement(item.id);
    await loadData();
    _feedbackMessage = 'Đã xóa "${item.productName}".';
    notifyListeners();
  }

  void clearFeedback() {
    if (_feedbackMessage == null) return;
    _feedbackMessage = null;
    notifyListeners();
  }
}
