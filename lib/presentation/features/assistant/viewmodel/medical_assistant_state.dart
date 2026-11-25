import '../../../../core/services/medical_assistant_service.dart';

class AssistantChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AssistantReplySource? source;
  final AssistantQuickRoute? suggestedRoute;
  final String? suggestedRouteLabel;

  const AssistantChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.source,
    this.suggestedRoute,
    this.suggestedRouteLabel,
  });
}

class MedicalAssistantState {
  final List<AssistantChatMessage> messages;
  final bool isLoading;
  final bool hasGeminiKey;
  final String selectedModel;
  final String activeMemberName;

  const MedicalAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.hasGeminiKey = false,
    this.selectedModel = 'gemini-3.6-flash',
    this.activeMemberName = 'Hồ sơ gốc',
  });

  MedicalAssistantState copyWith({
    List<AssistantChatMessage>? messages,
    bool? isLoading,
    bool? hasGeminiKey,
    String? selectedModel,
    String? activeMemberName,
  }) {
    return MedicalAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      hasGeminiKey: hasGeminiKey ?? this.hasGeminiKey,
      selectedModel: selectedModel ?? this.selectedModel,
      activeMemberName: activeMemberName ?? this.activeMemberName,
    );
  }
}
