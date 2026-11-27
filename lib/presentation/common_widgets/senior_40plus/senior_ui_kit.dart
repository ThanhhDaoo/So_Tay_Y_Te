import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../layout/app_layout_tokens.dart';

/// Bộ UI Kit Sổ Tay Y Tế chuẩn người lớn tuổi (40+):
/// Thẩm mỹ Y tế số hiện đại — nền sáng sạch (#F8FAFC / #FFFFFF), viền mảnh #EAECF0,
/// xanh Sapphire (#1E56A0) & xanh Ngọc lục bảo (#0E9F6E), chữ tiếng Việt thanh thoát, dễ đọc.
class SeniorTokens {
  SeniorTokens._();

  static const double sectionGap = 24.0;
  static const double cardPadding = 20.0;
  static const double cardRadius = 16.0;
  static const double minButtonHeight = 52.0;
  static const double iconSize = 26.0;
  static const double iconSizeLarge = 28.0;

  static const double bodyFontSize = 16.0;
  static const double cardTitleFontSize = 18.5;
  static const double sectionTitleFontSize = 19.0;
  static const double vitalMetricFontSize = 30.0;

  static const Color callActionGreen = AppColors.reportTeal; // #0E9F6E
  static const Color callActionGreenSoft = AppColors.reportTealSoft; // #ECFDF3
  static const Color warningAmberBg = AppColors.iceAllergyBg; // #FFFBEB
  static const Color warningAmberBorder = AppColors.iceAllergyBorder; // #FDE68A
  static const Color warningAmberText = AppColors.iceCriticalBadge; // #B45309
  static const Color highBpRedBg = AppColors.iceDangerBg; // #FEF2F2
  static const Color highBpRedText = AppColors.iceDangerText; // #DC2626
}

/// Thanh tiêu đề nền trắng tinh khiết, đường viền đáy mảnh #EAECF0 chuyên nghiệp.
class MedVaultGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;

  const MedVaultGlassAppBar({
    super.key,
    required this.title,
    this.eyebrow = 'Sổ Tay Y Tế',
    this.onBack,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayoutTokens.screenPadding,
        topPadding + 8,
        AppLayoutTokens.screenPadding,
        10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: AppColors.iceCardBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Material(
              color: AppColors.iceBackground,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.iceCardBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: 19,
                        color: AppColors.iceTextNavy,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Quay lại',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.iceTextNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.iceAccentCream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/img_sotayyte_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
                color: AppColors.iceTextNavy,
                height: 1.25,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Khối chức năng (Section) thoáng đãng, chữ tiêu đề rõ nét (#101828) & phụ đề xám dịu (#667085).
class SeniorSectionBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? iconAsset;
  final Color iconColor;
  final Color? iconBgColor;
  final Widget? trailing;
  final Widget child;
  final double bottomSpacing;

  const SeniorSectionBlock({
    super.key,
    required this.title,
    this.icon,
    this.iconAsset,
    required this.child,
    this.subtitle,
    this.iconColor = AppColors.primary,
    this.iconBgColor,
    this.trailing,
    this.bottomSpacing = SeniorTokens.sectionGap,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    if (iconAsset != null) {
      leading = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconBgColor ?? AppColors.iceAccentCream,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          iconAsset!,
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      );
    } else if (icon != null) {
      leading = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconBgColor ?? AppColors.iceAccentCream,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: iconColor),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (leading != null) ...[
                          leading,
                          const SizedBox(width: 9),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: SeniorTokens.sectionTitleFontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.25,
                              color: AppColors.iceTextNavy,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.iceTextMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Thẻ nền trắng tinh khiết (#FFFFFF), bo góc 16px, viền mảnh 1px #EAECF0, đổ bóng cực nhẹ.
class SeniorCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const SeniorCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SeniorTokens.cardPadding),
    this.backgroundColor = AppColors.surfaceLight,
    this.borderColor,
    this.borderWidth = 1.0,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SeniorTokens.cardRadius);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? AppColors.iceCardBorder,
          width: borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08101828),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );
  }
}

enum SeniorButtonVariant {
  primary,
  secondaryOutline,
  callNow,
  amberHighlight,
}

/// Nút bấm lớn chuẩn 40+ (chiều cao >= 52px): Xanh y tế chủ đạo, Xanh lá xác nhận/gọi điện,
/// Xanh nhạt hỗ trợ và Trắng viền xám thanh lịch.
class SeniorActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final SeniorButtonVariant variant;
  final bool expand;
  final double minHeight;

  const SeniorActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.variant = SeniorButtonVariant.primary,
    this.expand = true,
    this.minHeight = SeniorTokens.minButtonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, iconTint, border) = switch (variant) {
      SeniorButtonVariant.primary => (
          AppColors.primary,
          Colors.white,
          Colors.white,
          BorderSide.none,
        ),
      SeniorButtonVariant.callNow => (
          AppColors.reportTeal,
          Colors.white,
          Colors.white,
          BorderSide.none,
        ),
      SeniorButtonVariant.amberHighlight => (
          AppColors.iceAccentCream,
          AppColors.primary,
          AppColors.primary,
          const BorderSide(color: AppColors.iceBorderCream, width: 1),
        ),
      SeniorButtonVariant.secondaryOutline => (
          AppColors.surfaceLight,
          AppColors.iceTextNavy,
          AppColors.primary,
          const BorderSide(color: AppColors.iceCardBorder, width: 1.2),
        ),
    };

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: Size(expand ? double.infinity : 112, minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border,
        ),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: iconTint),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: fg,
                height: 1.22,
              ),
            ),
          ),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Nút phụ dạng Pill kèm icon & nhãn tiếng Việt rõ ràng.
class SeniorLabeledIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color? backgroundColor;

  const SeniorLabeledIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.iceAccentCream,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ lưới Tiện ích sức khỏe (2x2) nền trắng sạch, ô icon màu dịu 46x46 tinh tế.
class SeniorBigGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? svgAsset;
  final Color accentColor;
  final Color? cardTint;
  final VoidCallback onTap;

  const SeniorBigGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.svgAsset,
    this.accentColor = AppColors.primary,
    this.cardTint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SeniorCard(
      onTap: onTap,
      backgroundColor: cardTint ?? AppColors.surfaceLight,
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.iceCardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: svgAsset != null
                    ? SvgPicture.asset(
                        svgAsset!,
                        width: 22,
                        height: 22,
                        colorFilter: ColorFilter.mode(
                          accentColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(icon, size: 24, color: accentColor),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.dotMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.iceTextNavy,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.iceTextMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô tinh chỉnh chỉ số y tế (30px tabular figures) sáng rõ, dễ bấm tăng/giảm.
class SeniorNumberStepperField extends StatelessWidget {
  final String label;
  final String unit;
  final int value;
  final int min;
  final int max;
  final int step;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const SeniorNumberStepperField({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.onChanged,
    this.min = 30,
    this.max = 260,
    this.step = 1,
    this.accentColor = AppColors.iceTextNavy,
  });

  Future<void> _openDirectInputDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: '$value');
    final typed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          '$label ($unit)',
          style: const TextStyle(
            fontSize: 18.5,
            fontWeight: FontWeight.w700,
            color: AppColors.iceTextNavy,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.iceBackground,
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.iceCardBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 16, color: AppColors.iceTextSlate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(96, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final parsed = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, parsed);
            },
            child: const Text(
              'Xong',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (typed != null) {
      onChanged(typed.clamp(min, max));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.iceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.iceCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openDirectInputDialog(context),
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.iceTextMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: accentColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.iceTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _StepIconBtn(
            icon: Icons.remove_rounded,
            semanticLabel: 'Giảm',
            onTap: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          const SizedBox(width: 8),
          _StepIconBtn(
            icon: Icons.add_rounded,
            semanticLabel: 'Tăng',
            onTap: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}

class _StepIconBtn extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  const _StepIconBtn({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.iceCardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              Text(
                semanticLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iceTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh điều hướng đáy 4 mục nền trắng tinh khiết, tab đang chọn nổi bật màu xanh y tế (#1E56A0).
class SeniorBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  const SeniorBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
  });

  static const _items = [
    (
      svg: null,
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
    ),
    (
      svg: 'assets/icons/ic_nav_timeline.svg',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      label: 'Bệnh án',
    ),
    (
      svg: 'assets/icons/ic_nav_prescription.svg',
      icon: Icons.medication_outlined,
      activeIcon: Icons.medication_rounded,
      label: 'Thuốc uống',
    ),
    (
      svg: 'assets/icons/ic_nav_profile.svg',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Tài khoản',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final activeIdx = selectedIndex.clamp(0, _items.length - 1);

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: AppColors.iceCardBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 68,
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isSelected = i == activeIdx;
            final iconColor =
                isSelected ? AppColors.primary : AppColors.iceTextMuted;
            final labelColor =
                isSelected ? AppColors.primary : AppColors.iceTextMuted;

            return Expanded(
              child: InkWell(
                onTap: () => onSelectTab(i),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 30,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: Center(
                            child: item.svg != null
                                ? SvgPicture.asset(
                                    item.svg!,
                                    width: 22,
                                    height: 22,
                                    colorFilter: ColorFilter.mode(
                                      iconColor,
                                      BlendMode.srcIn,
                                    ),
                                  )
                                : Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 25,
                                    color: iconColor,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: labelColor,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
