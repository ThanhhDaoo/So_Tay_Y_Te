import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Khối định danh bệnh nhân & thời gian thực trên Trang chủ Sổ Tay Y Tế:
/// Kết hợp hàng chào hỏi sáng thoáng (Avatar + Họ tên, Tuổi, Giới tính + Nút Thẻ ICE)
/// và thẻ Banner Xanh Y Tế hiển thị Thứ, Ngày & Giờ hiện tại rõ nét cho người lớn tuổi.
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
    return 'Chưa cập nhật';
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
      width: 56,
      height: 56,
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
              size: 28,
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
        // 1. Hàng định danh bệnh nhân sáng thoáng trên nền trắng/sáng
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.iceCardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06101828),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onTapProfile,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      _buildPortrait(),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xin chào,',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.iceTextMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: AppColors.iceTextNavy,
                                height: 1.22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.ageLabel} • Giới tính: $genderText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
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
              const SizedBox(width: 10),
              Material(
                color: AppColors.iceDangerBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.onOpenEmergencyCard,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.iceDangerText.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/ic_nav_ice.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            AppColors.iceDangerText,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 3),
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
        const SizedBox(height: 14),

        // 2. Banner Xanh Y Tế hiển thị Thời gian thực & Nhật ký sức khỏe trong ngày
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF1E56A0),
                Color(0xFF4277C6),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x221E56A0),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -14,
                  child: Opacity(
                    opacity: 0.16,
                    child: SvgPicture.asset(
                      'assets/icons/ic_prof_shield_watermark.svg',
                      width: 104,
                      height: 104,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Sổ Tay Y Tế • Nhật ký hôm nay',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              fontFeatures: [FontFeature.tabularFigures()],
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              dateText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFEAF2FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Đo huyết áp và uống thuốc đúng cữ để ổn định sức khỏe mỗi ngày',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFDCE8FF),
                          height: 1.35,
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
