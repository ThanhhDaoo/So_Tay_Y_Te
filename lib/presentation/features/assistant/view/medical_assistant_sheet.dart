import 'package:flutter/material.dart';
import '../../../../core/services/medical_assistant_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../viewmodel/medical_assistant_state.dart';
import '../viewmodel/medical_assistant_viewmodel.dart';

class MedicalAssistantSheet extends StatefulWidget {
  final ValueChanged<int>? onSwitchMainTab;
  final MedicalAssistantViewModel? viewModel;

  const MedicalAssistantSheet({
    super.key,
    this.onSwitchMainTab,
    this.viewModel,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<int>? onSwitchMainTab,
    MedicalAssistantViewModel? viewModel,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicalAssistantSheet(
        onSwitchMainTab: onSwitchMainTab,
        viewModel: viewModel,
      ),
    );
  }

  @override
  State<MedicalAssistantSheet> createState() => _MedicalAssistantSheetState();
}

class _MedicalAssistantSheetState extends State<MedicalAssistantSheet> {
  late final MedicalAssistantViewModel _viewModel;
  late final bool _ownsViewModel;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<({String label, String prompt})> _quickPrompts = [
    (
      label: '📊 Số lượng bệnh án',
      prompt: 'Thống kê số lượng bệnh án của tôi',
    ),
    (
      label: '💊 Đơn thuốc đang uống',
      prompt: 'Đơn thuốc đang uống của tôi gồm những gì?',
    ),
    (
      label: '👤 Thông tin & Dị ứng',
      prompt: 'Cho xem thông tin cá nhân, nhóm máu và dị ứng của chủ tài khoản',
    ),
    (
      label: '❤️ Chỉ số sinh hiệu',
      prompt: 'Chỉ số huyết áp và nhịp tim gần nhất của tôi',
    ),
    (
      label: '🩺 Tham khảo triệu chứng',
      prompt: 'Mình bị sốt nhẹ kèm đau họng và mệt mỏi 2 ngày nay thì có thể liên quan đến gì?',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _ownsViewModel = false;
    } else {
      _viewModel = MedicalAssistantViewModel();
      _ownsViewModel = true;
    }
    _viewModel.addListener(_scrollToBottomSoon);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_scrollToBottomSoon);
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _handleSend([String? presetPrompt]) async {
    final text = (presetPrompt ?? _inputController.text).trim();
    if (text.isEmpty) return;
    if (presetPrompt == null) {
      _inputController.clear();
    }
    FocusScope.of(context).unfocus();
    await _viewModel.sendMessage(text);
  }

  void _handleQuickRoute(AssistantQuickRoute route) {
    Navigator.of(context).pop();
    switch (route) {
      case AssistantQuickRoute.timeline:
        if (widget.onSwitchMainTab != null) {
          widget.onSwitchMainTab!(0);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.timeline);
        }
        break;
      case AssistantQuickRoute.prescriptions:
        if (widget.onSwitchMainTab != null) {
          widget.onSwitchMainTab!(1);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.prescriptions);
        }
        break;
      case AssistantQuickRoute.profile:
        if (widget.onSwitchMainTab != null) {
          widget.onSwitchMainTab!(3);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
        }
        break;
      case AssistantQuickRoute.documents:
        Navigator.of(context).pushNamed(AppRoutes.documents);
        break;
      case AssistantQuickRoute.vitalReports:
        Navigator.of(context).pushNamed(AppRoutes.vitalReports);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;
    final sheetHeight = (media.size.height * 0.86).clamp(420.0, 820.0);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFBF9F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              final state = _viewModel.state;

              return Column(
                children: [
                  // Drag handle + Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFECE7DF)),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4E5547), Color(0xFF2F362B)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.health_and_safety_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Trợ Lý Sổ Tay Y Tế',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.iceTextNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          'Hồ sơ: ${state.activeMemberName} • Sẵn sàng hỗ trợ',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.iceTextSlate,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Làm mới hội thoại',
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: AppColors.iceTextSlate,
                              ),
                              onPressed: state.isLoading
                                  ? null
                                  : () => _viewModel.clearChat(),
                            ),
                            IconButton(
                              tooltip: 'Đóng',
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 21,
                                color: AppColors.iceTextMuted,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Medical Disclaimer Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFBEB),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFFDE68A)),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Tham khảo triệu chứng không phải chẩn đoán xác định (nhiều bệnh có chung biểu hiện) và không thay thế ý kiến bác sĩ.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      itemCount:
                          state.messages.length + (state.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.messages.length) {
                          return const _TypingIndicatorBubble();
                        }
                        final msg = state.messages[index];
                        return _MessageBubble(
                          message: msg,
                          onQuickRouteTap: msg.suggestedRoute != null
                              ? () => _handleQuickRoute(msg.suggestedRoute!)
                              : null,
                        );
                      },
                    ),
                  ),

                  // Quick Prompt Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _quickPrompts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final item = _quickPrompts[index];
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFDFD8CC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          label: Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF332717),
                            ),
                          ),
                          onPressed: state.isLoading
                              ? null
                              : () => _handleSend(item.prompt),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Input Bar
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      10 + (bottomInset > 0 ? 0 : safeBottom),
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFECE7DF)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            textInputAction: TextInputAction.send,
                            minLines: 1,
                            maxLines: 3,
                            onSubmitted: (_) => _handleSend(),
                            style: const TextStyle(fontSize: 13.5),
                            decoration: InputDecoration(
                              hintText:
                                  'Hỏi bệnh án, đơn thuốc hoặc mô tả triệu chứng...',
                              hintStyle: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.iceTextMuted,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF6F4EE),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: state.isLoading
                              ? Colors.grey[400]
                              : AppColors.iceOlive,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: state.isLoading ? null : () => _handleSend(),
                            child: const Padding(
                              padding: EdgeInsets.all(11),
                              child: Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final AssistantChatMessage message;
  final VoidCallback? onQuickRouteTap;

  const _MessageBubble({
    required this.message,
    this.onQuickRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser && message.source != null) ...[
            _SourceBadge(source: message.source!),
            const SizedBox(height: 4),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.84,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF3E4638) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser
                  ? null
                  : Border.all(color: const Color(0xFFE8E2D7)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormattedMessageText(
                  text: message.text,
                  isUser: isUser,
                ),
                if (!isUser &&
                    onQuickRouteTap != null &&
                    message.suggestedRouteLabel != null) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onQuickRouteTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFE6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD8C8AE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              message.suggestedRouteLabel!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF433624),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Color(0xFF433624),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final AssistantReplySource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, icon) = switch (source) {
      AssistantReplySource.localDatabase => (
          'Dữ liệu Sổ Tay (Offline)',
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          Icons.folder_special_rounded,
        ),
      AssistantReplySource.geminiAi => (
          'Tham khảo AI (Gemini)',
          const Color(0xFFEDE9FE),
          const Color(0xFF5B21B6),
          Icons.auto_awesome_rounded,
        ),
      AssistantReplySource.localSymptomFallback => (
          'Hướng dẫn Tham khảo An toàn',
          const Color(0xFFFEF3C7),
          const Color(0xFF92400E),
          Icons.shield_outlined,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hiển thị văn bản có hỗ trợ in đậm `**...**` nhẹ nhàng mà không cần thêm thư viện ngoài.
class _FormattedMessageText extends StatelessWidget {
  final String text;
  final bool isUser;

  const _FormattedMessageText({
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 13.2,
      height: 1.42,
      color: isUser ? Colors.white : AppColors.iceTextNavy,
    );
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
    final italicStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);

    final cleaned = text.replaceAllMapped(
      RegExp(r'^#{1,4}\s+', multiLine: true),
      (_) => '',
    );

    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|_([^_\n]+)_');
    int lastEnd = 0;

    for (final match in regex.allMatches(cleaned)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: cleaned.substring(lastEnd, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(text: match.group(1), style: boldStyle));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(text: match.group(2), style: italicStyle));
      }
      lastEnd = match.end;
    }
    if (lastEnd < cleaned.length) {
      spans.add(TextSpan(text: cleaned.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E2D7)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.iceOlive,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Trợ lý đang tổng hợp thông tin...',
              style: TextStyle(fontSize: 12, color: AppColors.iceTextSlate),
            ),
          ],
        ),
      ),
    );
  }
}
