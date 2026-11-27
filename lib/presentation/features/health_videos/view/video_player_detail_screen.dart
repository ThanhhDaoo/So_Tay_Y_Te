import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/health_video.dart';
import '../../../common_widgets/layout/app_layout_tokens.dart';
import '../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Trình phát Video sức khỏe trực quan cho người lớn tuổi (40+):
/// Khung phát cỡ lớn, bộ nút Phát / Tạm dừng / Lùi 15s / Tiến 15s kèm chữ tiếng Việt rõ ràng,
/// tự động đồng bộ bước tập hiện tại & hỗ trợ mở xem video gốc toàn màn hình.
class VideoPlayerDetailScreen extends StatefulWidget {
  final HealthVideo video;
  final VoidCallback? onToggleSave;

  const VideoPlayerDetailScreen({
    super.key,
    required this.video,
    this.onToggleSave,
  });

  @override
  State<VideoPlayerDetailScreen> createState() =>
      _VideoPlayerDetailScreenState();
}

class _VideoPlayerDetailScreenState extends State<VideoPlayerDetailScreen> {
  Timer? _playbackTimer;
  bool _isPlaying = true;
  late bool _isSaved;
  late int _totalSeconds;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.video.isSaved;
    final mins = int.tryParse(
          widget.video.durationLabel.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        10;
    _totalSeconds = (mins * 60).clamp(60, 3600);
    _startTimer();
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isPlaying) return;
      setState(() {
        if (_elapsedSeconds < _totalSeconds) {
          _elapsedSeconds++;
        } else {
          _isPlaying = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  String _formatClock(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get _activeStepIndex {
    if (widget.video.keySteps.isEmpty) return 0;
    final progress = _elapsedSeconds / _totalSeconds;
    return (progress * widget.video.keySteps.length)
        .floor()
        .clamp(0, widget.video.keySteps.length - 1);
  }

  Future<void> _openExternalStream() async {
    final rawUrl = widget.video.videoUrl.trim();
    if (rawUrl.isEmpty) return;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không thể mở trình phát ngoài. Mời bác tập theo trình hướng dẫn trực tiếp trên màn hình.',
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final v = widget.video;
    final ratio = (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0);
    final currentStepText = v.keySteps.isNotEmpty
        ? v.keySteps[_activeStepIndex]
        : v.description;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 146,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
          child: SeniorLabeledIconButton(
            icon: Icons.arrow_back_rounded,
            label: 'Quay lại',
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Trình Phát Bài Tập',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.iceTextNavy,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppLayoutTokens.screenPadding,
          12,
          AppLayoutTokens.screenPadding,
          bottomPad + 36,
        ),
        children: [
          // KHUNG TRÌNH PHÁT VIDEO CỠ LỚN
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: const Color(0xFF1A221E),
              child: Column(
                children: [
                  SizedBox(
                    height: 224,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (v.thumbnailUrl.startsWith('assets/'))
                          Opacity(
                            opacity: 0.42,
                            child: Image.asset(
                              v.thumbnailUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x55000000),
                                Color(0xCC0D1411),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isPlaying
                                            ? SeniorTokens.callActionGreen
                                            : Colors.orange.shade800,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isPlaying
                                                ? Icons.graphic_eq_rounded
                                                : Icons
                                                    .pause_circle_filled_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              _isPlaying
                                                  ? 'Đang phát'
                                                  : 'Tạm dừng',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_formatClock(_elapsedSeconds)} / ${_formatClock(_totalSeconds)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Phụ đề động tác to rõ ngay trên khung video
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.68),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  currentStepText,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Thanh kéo tiến trình & 3 nút điều khiển lớn có nhãn chữ tiếng Việt
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 8,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 11,
                            ),
                          ),
                          child: Slider(
                            value: ratio,
                            activeColor: const Color(0xFF4ADE80),
                            inactiveColor: Colors.white24,
                            onChanged: (v) {
                              setState(() {
                                _elapsedSeconds = (v * _totalSeconds).round();
                              });
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _PlayerControlBtn(
                                icon: Icons.replay_10_rounded,
                                label: 'Lùi 15 giây',
                                onTap: () => setState(() {
                                  _elapsedSeconds =
                                      (_elapsedSeconds - 15).clamp(0, _totalSeconds);
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PlayerControlBtn(
                                icon: _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                label: _isPlaying ? 'Tạm dừng' : 'Phát tiếp',
                                isPrimary: true,
                                onTap: () =>
                                    setState(() => _isPlaying = !_isPlaying),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PlayerControlBtn(
                                icon: Icons.forward_10_rounded,
                                label: 'Tiến 15 giây',
                                onTap: () => setState(() {
                                  _elapsedSeconds =
                                      (_elapsedSeconds + 15).clamp(0, _totalSeconds);
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nút mở nguồn phát YouTube / Video gốc toàn màn hình & Nút Lưu yêu thích
          SeniorActionButton(
            label: 'Mở xem Video gốc toàn màn hình',
            icon: Icons.open_in_new_rounded,
            variant: SeniorButtonVariant.amberHighlight,
            onPressed: _openExternalStream,
          ),
          const SizedBox(height: 12),
          SeniorActionButton(
            label: _isSaved
                ? 'Đã lưu vào Video yêu thích'
                : 'Lưu bài tập này để xem lại',
            icon: _isSaved
                ? Icons.bookmark_added_rounded
                : Icons.bookmark_add_outlined,
            variant: SeniorButtonVariant.secondaryOutline,
            onPressed: () {
              setState(() => _isSaved = !_isSaved);
              widget.onToggleSave?.call();
            },
          ),
          const SizedBox(height: SeniorTokens.sectionGap),

          // Thông tin chi tiết & Các bước tập chữ to
          SeniorCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPeach,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${v.category} • Thời lượng: ${v.durationLabel}',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  v.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.iceTextNavy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hướng dẫn: ${v.instructorName}',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  v.description,
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: AppColors.iceTextSlate,
                    height: 1.45,
                  ),
                ),
                if (v.keySteps.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Hướng dẫn từng bước dễ tập theo:',
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (int i = 0; i < v.keySteps.length; i++) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: i == _activeStepIndex
                            ? SeniorTokens.callActionGreenSoft
                            : AppColors.surfaceCream,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: i == _activeStepIndex
                              ? SeniorTokens.callActionGreen
                              : AppColors.iceCardBorder,
                          width: i == _activeStepIndex ? 1.8 : 1.0,
                        ),
                      ),
                      child: Text(
                        v.keySteps[i],
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.iceTextNavy,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _PlayerControlBtn({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? SeniorTokens.callActionGreen
          : Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
