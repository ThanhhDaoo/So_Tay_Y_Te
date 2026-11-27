import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Khối định danh bệnh nhân & thời gian thực trên Trang chủ Sổ Tay Y Tế:
/// Tỷ lệ chữ và khoảng cách cân đối chuẩn di động, không tràn viền hay rớt dòng.
class HomeUserTimeHeader extends StatefulWidget {
  final String fullName;
  final String ageLabel;
  final String genderLabel;
  final String? avatarPath;
  final VoidCallback onOpenEmergencyCard;
  final VoidCallback onTapProfile;

  const HomeUserTimeHeader({
    super.key,
    required this.fullName,
    required this.ageLabel,
    required this.genderLabel,
    this.avatarPath,
    required this.onOpenEmergencyCard,
    required this.onTapProfile,
  });

  @override
  State<HomeUserTimeHeader> createState() => _HomeUserTimeHeaderState();
}

class _HomeUserTimeHeaderState extends State<HomeUserTimeHeader> {
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _weekdayVi(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
      default:
        return 'Chủ Nhật';
    }
  }

  String _normalizeGender(String raw) {
    final g = raw.toLowerCase();
    if (g.contains('nữ') || g.contains('female')) return 'Nữ';
    if (g.contains('nam') || g.contains('male')) return 'Nam';
    return 'Chưa rõ';
  }

  IconData _genderFallbackIcon(String raw) {
    final g = raw.toLowerCase();
    if (g.contains('nữ') || g.contains('female')) return Icons.face_3_outlined;
    if (g.contains('nam') || g.contains('male')) return Icons.face_6_outlined;
    return Icons.person_outline_rounded;
  }

  Widget _buildPortrait() {
    final path = widget.avatarPath;
    ImageProvider? provider;
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('assets/')) {
        provider = AssetImage(path);
      } else if (!path.startsWith('http') && File(path).existsSync()) {
        provider = FileImage(File(path));
      }
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.iceAccentCream,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.iceBorderCream, width: 1.5),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
      ),
      child: provider == null
          ? Icon(
              _genderFallbackIcon(widget.genderLabel),
              size: 24,
              color: AppColors.primary,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_weekdayVi(_now.weekday)}, ${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}/${_now.year}';
    final timeText =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final genderText = _normalizeGender(widget.genderLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.iceCardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onTapProfile,
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      _buildPortrait(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xin chào,',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: AppColors.iceTextMuted,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: AppColors.iceTextNavy,
                                height: 1.22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.ageLabel} • Giới tính: $genderText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.iceTextSlate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.iceDangerBg,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: widget.onOpenEmergencyCard,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.iceDangerText.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_nav_ice.svg',
                          width: 15,
                          height: 15,
                          colorFilter: const ColorFilter.mode(
                            AppColors.iceDangerText,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'Thẻ ICE',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.iceDangerText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF1E56A0),
                Color(0xFF3E74C2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1E1E56A0),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned(
                  right: -6,
                  bottom: -12,
                  child: Opacity(
                    opacity: 0.14,
                    child: SvgPicture.asset(
                      'assets/icons/ic_prof_shield_watermark.svg',
                      width: 88,
                      height: 88,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Sổ Tay Y Tế • Nhật ký hôm nay',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              dateText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFEAF2FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Đo huyết áp và uống thuốc đúng giờ mỗi ngày',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFDCE8FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
