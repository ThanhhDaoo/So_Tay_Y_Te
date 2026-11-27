import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../layout/app_layout_tokens.dart';

/// Bộ UI Kit Sổ Tay Y Tế tinh chỉnh tỷ lệ hài hòa chuẩn di động:
/// Chữ rõ nét vừa vặn (14.5px - 17px), chỉ số y tế 23px - 24px gọn 1 dòng,
/// nút bấm >= 52px một hàng chữ, không tràn viền hay rớt dòng vụn.
class SeniorTokens {
  SeniorTokens._();

  static const double sectionGap = 22.0;
  static const double cardPadding = 16.0;
  static const double cardRadius = 14.0;
  static const double minButtonHeight = 52.0;
  static const double iconSize = 22.0;
  static const double iconSizeLarge = 24.0;

  static const double bodyFontSize = 14.5;
  static const double cardTitleFontSize = 16.0;
  static const double sectionTitleFontSize = 17.0;
  static const double vitalMetricFontSize = 24.0;

  static const Color callActionGreen = AppColors.reportTeal;
  static const Color callActionGreenSoft = AppColors.reportTealSoft;
  static const Color warningAmberBg = AppColors.iceAllergyBg;
  static const Color warningAmberBorder = AppColors.iceAllergyBorder;
  static const Color warningAmberText = AppColors.iceCriticalBadge;
  static const Color highBpRedBg = AppColors.iceDangerBg;
  static const Color highBpRedText = AppColors.iceDangerText;
}

/// Thanh tiêu đề nền trắng tinh khiết, cân đối chuẩn iOS / OneCare.
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
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppLayoutTokens.screenPadding,
        topPadding + 6,
        AppLayoutTokens.screenPadding,
        8,
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
            Tooltip(
              message: 'Quay lại',
              child: Material(
                color: AppColors.iceBackground,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.iceCardBorder),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.iceTextNavy,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Image.asset(
              'assets/images/img_sotayyte_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.iceTextNavy,
                height: 1.2,
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

/// Khối chức năng (Section) gọn gàng, tiêu đề 17px rõ nét, phụ đề 13px không lấn át nội dung.
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: iconBgColor ?? AppColors.iceAccentCream,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          iconAsset!,
          width: 15,
          height: 15,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
      );
    } else if (icon != null) {
      leading = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: iconBgColor ?? AppColors.iceAccentCream,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: iconColor),
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
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: SeniorTokens.sectionTitleFontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.iceTextNavy,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.iceTextMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Thẻ nền trắng tinh khiết (#FFFFFF), bo góc 14px, viền mảnh 1px #EAECF0.
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
            color: Color(0x06101828),
            blurRadius: 10,
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

/// Nút bấm chuẩn (>= 52px), chữ 15px gọn trên 1 dòng duy nhất, không bị rớt chữ.
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
          const BorderSide(color: AppColors.iceCardBorder, width: 1),
        ),
    };

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: Size(expand ? double.infinity : 104, minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border,
        ),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 19, color: iconTint),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Nút phụ dạng Pill gọn sắc kèm icon & nhãn tiếng Việt.
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
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
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

/// Thẻ lưới Tiện ích sức khỏe (2x2) cân đối, không bị chật hay rớt 3-4 dòng.
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
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.iceCardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: svgAsset != null
                    ? SvgPicture.asset(
                        svgAsset!,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          accentColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(icon, size: 21, color: accentColor),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.dotMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
              color: AppColors.iceTextNavy,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.iceTextMuted,
              height: 1.32,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô tinh chỉnh chỉ số y tế gọn gàng (24px tabular figures), không chèn ép nút [-] [+].
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$label ($unit)',
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: AppColors.iceTextNavy,
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.iceBackground,
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.iceCardBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 14.5, color: AppColors.iceTextSlate),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(88, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final parsed = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, parsed);
            },
            child: const Text(
              'Xong',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.iceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.iceCardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _openDirectInputDialog(context),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.iceTextMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$value',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: accentColor,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          unit,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.iceTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _StepIconBtn(
            icon: Icons.remove_rounded,
            semanticLabel: 'Giảm',
            onTap: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          const SizedBox(width: 6),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.iceCardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.primary),
              Text(
                semanticLabel,
                style: const TextStyle(
                  fontSize: 10,
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

/// Thanh điều hướng đáy 4 mục nền trắng tinh khiết, gọn gàng chuẩn iOS.
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
            color: Color(0x08101828),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 62,
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
                          width: 28,
                          height: 2.5,
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
                          width: 24,
                          height: 24,
                          child: Center(
                            child: item.svg != null
                                ? SvgPicture.asset(
                                    item.svg!,
                                    width: 20,
                                    height: 20,
                                    colorFilter: ColorFilter.mode(
                                      iconColor,
                                      BlendMode.srcIn,
                                    ),
                                  )
                                : Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 23,
                                    color: iconColor,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
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
