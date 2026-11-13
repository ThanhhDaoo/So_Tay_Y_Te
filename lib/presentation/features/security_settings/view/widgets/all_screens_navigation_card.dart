import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../routes/app_routes.dart';
import '../../../main_shell/view/main_shell_screen.dart';

/// Thẻ điều hướng danh mục 8 màn hình chuẩn theo Figma
class AllScreensNavigationCard extends StatelessWidget {
  final ValueChanged<int>? onSelectMainTab;

  const AllScreensNavigationCard({
    super.key,
    this.onSelectMainTab,
  });

  void _switchTab(BuildContext context, int tabIndex) {
    if (onSelectMainTab != null) {
      onSelectMainTab!(tabIndex);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShellScreen(initialIndex: tabIndex),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _ScreenEntry(
        number: '1',
        title: 'Thẻ Cấp Cứu Khẩn Cấp (ICE)',
        subtitle: 'Tab trung tâm ICE • Nút đỏ lớn',
        icon: Icons.emergency_rounded,
        color: const Color(0xFFBA1A1A),
        onTap: () => _switchTab(context, 2),
      ),
      _ScreenEntry(
        number: '2',
        title: 'Dòng Thời Gian Bệnh Án',
        subtitle: 'Tab 1 • Trục sự kiện y tế',
        icon: Icons.timeline_rounded,
        color: AppColors.iceOlive,
        onTap: () => _switchTab(context, 0),
      ),
      _ScreenEntry(
        number: '3',
        title: 'Quản Lý Toa Thuốc & Lịch Uống',
        subtitle: 'Tab 2 • Nhắc thuốc thông minh',
        icon: Icons.medication_rounded,
        color: const Color(0xFF2E6B5E),
        onTap: () => _switchTab(context, 1),
      ),
      _ScreenEntry(
        number: '4',
        title: 'Hồ Sơ Y Tế Nền & Gia Đình',
        subtitle: 'Tab 4 • Chỉ số & switcher gia đình',
        icon: Icons.person_pin_rounded,
        color: const Color(0xFF6C5C45),
        onTap: () => _switchTab(context, 3),
      ),
      _ScreenEntry(
        number: '5',
        title: 'Kho Tài Liệu & Quét OCR',
        subtitle: 'Quản lý 12 tệp X-quang, MRI, xét nghiệm',
        icon: Icons.folder_shared_rounded,
        color: const Color(0xFF1B6B93),
        badgeText: 'MÀN HÌNH 5',
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.documents),
      ),
      _ScreenEntry(
        number: '6',
        title: 'Gói Vault Pro & Đồng Bộ Cloud',
        subtitle: 'Gói đăng ký nâng cao & sao lưu 2 chiều',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFFB57C2F),
        badgeText: 'MÀN HÌNH 6',
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.paywall),
      ),
      _ScreenEntry(
        number: '7',
        title: 'Báo Cáo Sinh Hiệu & Xuất PDF',
        subtitle: 'Bản xem trước A4 y khoa & AirPrint',
        icon: Icons.picture_as_pdf_rounded,
        color: const Color(0xFF7A4069),
        badgeText: 'MÀN HÌNH 7',
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.vitalReports),
      ),
      _ScreenEntry(
        number: '8',
        title: 'Bảo Mật & Khóa Sinh Trắc Học',
        subtitle: 'Tab 5 (Đang xem) • Mã hóa AES-256',
        icon: Icons.shield_rounded,
        color: AppColors.secOlive,
        badgeText: 'ĐANG XEM',
        isCurrent: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.dashboard_customize_outlined,
                size: 18,
                color: AppColors.secOlive,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Danh Mục 8 Màn Hình Figma',
                  style: AppTypography.heading3.copyWith(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFE3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '8 / 8 SCREENS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secOlive,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secCardBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < screens.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 0.6, indent: 56, endIndent: 16),
                _ScreenTile(entry: screens[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScreenEntry {
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badgeText;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _ScreenEntry({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badgeText,
    this.isCurrent = false,
    this.onTap,
  });
}

class _ScreenTile extends StatelessWidget {
  final _ScreenEntry entry;

  const _ScreenTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.isCurrent ? null : entry.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    entry.icon,
                    size: 20,
                    color: entry.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          '${entry.number}. ${entry.title}',
                          style: AppTypography.labelSemiBold.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: entry.isCurrent
                                ? AppColors.secOlive
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        if (entry.badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: entry.isCurrent
                                  ? const Color(0xFFE8EFE3)
                                  : const Color(0xFFF0EEE9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              entry.badgeText!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: entry.isCurrent
                                    ? AppColors.secOlive
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!entry.isCurrent)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFFB0B0A8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
