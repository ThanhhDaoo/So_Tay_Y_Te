import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../common_widgets/senior_40plus/senior_ui_kit.dart';

/// Khối 1 trên Trang chủ: Hiển thị rõ Thứ, Ngày/Tháng/Năm, Giờ hiện tại
/// và Họ tên, Tuổi, Giới tính kèm Ảnh đại diện / Icon trực quan theo giới tính.
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

  String _greetingByHour(int hour) {
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  (IconData, Color, String) _genderVisual(String rawGender) {
    final g = rawGender.toLowerCase();
    if (g.contains('nữ') || g.contains('female')) {
      return (Icons.face_3_rounded, const Color(0xFFB84B6E), 'Nữ');
    }
    if (g.contains('nam') || g.contains('male')) {
      return (Icons.face_6_rounded, const Color(0xFF285E8E), 'Nam');
    }
    return (Icons.person_rounded, AppColors.primary, 'Chưa rõ giới tính');
  }

  Widget _buildAvatar(IconData genderIcon, Color genderColor) {
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
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: genderColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: genderColor.withValues(alpha: 0.45), width: 2.2),
        image: provider != null
            ? DecorationImage(image: provider, fit: BoxFit.cover)
            : null,
      ),
      child: provider == null
          ? Icon(genderIcon, size: 38, color: genderColor)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_weekdayVi(_now.weekday)}, ngày ${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}/${_now.year}';
    final timeText =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final (genderIcon, genderColor, normalizedGender) =
        _genderVisual(widget.genderLabel);

    return SeniorCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.iceBorderCream,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng Thời gian thực & Nút Thẻ Cấp Cứu
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.iceCardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 24,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$dateText • $timeText',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SeniorLabeledIconButton(
                icon: Icons.emergency_rounded,
                label: 'Cấp cứu',
                color: AppColors.iceDangerText,
                backgroundColor: AppColors.iceDangerBg.withValues(alpha: 0.65),
                onTap: widget.onOpenEmergencyCard,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),

          // Hàng Thông tin Bệnh nhân (Họ tên, Tuổi, Giới tính + Ảnh/Icon giới tính)
          InkWell(
            onTap: widget.onTapProfile,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                _buildAvatar(genderIcon, genderColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingByHour(_now.hour),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iceTextSlate,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.fullName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.iceTextNavy,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoPill(
                            icon: Icons.cake_rounded,
                            label: widget.ageLabel,
                            tint: AppColors.accent,
                          ),
                          _InfoPill(
                            icon: genderIcon,
                            label: 'Giới tính: $normalizedGender',
                            tint: genderColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: tint),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
