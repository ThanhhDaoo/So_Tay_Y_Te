import 'package:flutter/foundation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/medical_assistant_service.dart';
import '../../../../core/services/user_session_manager.dart';
import 'medical_assistant_state.dart';

class MedicalAssistantViewModel extends ChangeNotifier {
  final MedicalAssistantService _service;
  MedicalAssistantState _state;

  MedicalAssistantState get state => _state;

  MedicalAssistantViewModel({
    MedicalAssistantService? service,
  })  : _service = service ??
            (sl.isRegistered<MedicalAssistantService>()
                ? sl<MedicalAssistantService>()
                : MedicalAssistantService()),
        _state = const MedicalAssistantState() {
    _initialize();
    AppSessionNotifier.instance.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    AppSessionNotifier.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    _refreshMemberHeader();
  }

  Future<void> _refreshMemberHeader() async {
    final snap = await _service.loadLocalSnapshot();
    final hasKey = await _service.hasApiKey();
    final model = await _service.getSelectedModel();
    _state = _state.copyWith(
      activeMemberName: snap.memberDisplayName,
      hasGeminiKey: hasKey,
      selectedModel: model,
    );
    notifyListeners();
  }

  Future<void> _initialize() async {
    final snap = await _service.loadLocalSnapshot();
    final hasKey = await _service.hasApiKey();
    final model = await _service.getSelectedModel();

    final welcomeMsg = AssistantChatMessage(
      id: 'welcome_0',
      isUser: false,
      timestamp: DateTime.now(),
      source: AssistantReplySource.localDatabase,
      text: 'Xin chào! Mình là **Trợ lý Sổ Tay Y Tế** đang hỗ trợ hồ sơ **${snap.memberDisplayName}**.\n\n'
          '• Hiện có **${snap.totalEvents} bệnh án** và **${snap.activePrescriptions} đơn thuốc đang uống**.\n'
          '• Bạn có thể hỏi nhanh số lượng bệnh án, thuốc, thông tin cá nhân/dị ứng (chạy **100% offline** trên máy) hoặc nhập triệu chứng để tham khảo định hướng ban đầu.',
    );

    _state = _state.copyWith(
      messages: [welcomeMsg],
      hasGeminiKey: hasKey,
      selectedModel: model,
      activeMemberName: snap.memberDisplayName,
    );
    notifyListeners();
  }

  Future<void> sendMessage(String rawText) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty || _state.isLoading) return;

    final userMsg = AssistantChatMessage(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final historyForAi = _state.messages
        .where((m) => m.id != 'welcome_0')
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'text': m.text,
            })
        .toList();

    _state = _state.copyWith(
      messages: [..._state.messages, userMsg],
      isLoading: true,
    );
    notifyListeners();

    try {
      final reply = await _service.answerUserQuery(
        trimmed,
        previousTurns: historyForAi,
      );
      final botMsg = AssistantChatMessage(
        id: 'a_${DateTime.now().microsecondsSinceEpoch}',
        text: reply.text,
        isUser: false,
        timestamp: DateTime.now(),
        source: reply.source,
        suggestedRoute: reply.suggestedRoute,
        suggestedRouteLabel: reply.suggestedRouteLabel,
      );
      _state = _state.copyWith(
        messages: [..._state.messages, botMsg],
        isLoading: false,
      );
    } catch (e) {
      final errMsg = AssistantChatMessage(
        id: 'err_${DateTime.now().microsecondsSinceEpoch}',
        text: 'Đã xảy ra lỗi khi xử lý câu hỏi. Vui lòng thử lại.',
        isUser: false,
        timestamp: DateTime.now(),
        source: AssistantReplySource.localSymptomFallback,
      );
      _state = _state.copyWith(
        messages: [..._state.messages, errMsg],
        isLoading: false,
      );
    }
    notifyListeners();
  }

  Future<String> getSavedApiKey() => _service.getConfiguredApiKey();

  Future<void> updateGeminiConfig({
    required String apiKey,
    required String model,
  }) async {
    await _service.saveApiKey(apiKey);
    await _service.saveSelectedModel(model);
    final hasKey = await _service.hasApiKey();
    final savedModel = await _service.getSelectedModel();
    _state = _state.copyWith(
      hasGeminiKey: hasKey,
      selectedModel: savedModel,
    );
    notifyListeners();
  }

  Future<void> clearChat() async {
    await _initialize();
  }
}
