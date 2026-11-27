import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';

/// Khối định danh & thời gian thực trên Trang chủ theo đúng ngôn ngữ thiết kế
/// Horizontal Identity Card của Figma gốc (tông Kem Cát ấm, watermark khiên y tế mờ, chữ thanh thoát).
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
    return 'Chưa cập nhật giới tính';
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
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.iceBorderCream, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120B1C30),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
      ),
      child: provider == null
          ? Icon(
              _genderFallbackIcon(widget.genderLabel),
              size: 30,
              color: AppColors.iceOlive,
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

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAF7F2),
            Color(0xFFF1E5D3),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.iceBorderCream.withValues(alpha: 0.75),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0B1C30),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -16,
              child: Opacity(
                opacity: 0.06,
                child: SvgPicture.asset(
                  'assets/icons/ic_prof_shield_watermark.svg',
                  width: 108,
                  height: 108,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dòng trên: Ngày, Thứ, Giờ hiện tại + Nút Thẻ Cấp Cứu ICE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.reportTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '$dateText  •  $timeText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.iceOliveDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.icePrimaryCall,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: widget.onOpenEmergencyCard,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/ic_nav_ice.svg',
                                  width: 14,
                                  height: 14,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Thẻ ICE',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.iceAccentCream,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: AppColors.iceBorderCream.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),

                  // Dòng dưới: Chân dung + Họ tên, Tuổi, Giới tính
                  InkWell(
                    onTap: widget.onTapProfile,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        _buildPortrait(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HỒ SƠ THEO DÕI HẰNG NGÀY',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                  color: AppColors.textWarmBrown,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.fullName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  color: AppColors.iceTextNavy,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${widget.ageLabel}  •  Giới tính: $genderText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.iceTextSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: AppColors.textWarmBrown,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
