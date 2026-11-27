import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../layout/app_layout_tokens.dart';

/// Hệ hằng số UI/UX bắt buộc dành riêng cho người trung niên & cao tuổi (40+).
class SeniorTokens {
  SeniorTokens._();

  static const double sectionGap = 24.0;
  static const double cardPadding = 20.0;
  static const double cardRadius = 18.0;
  static const double minButtonHeight = 54.0;
  static const double iconSize = 30.0;
  static const double iconSizeLarge = 32.0;

  static const double bodyFontSize = 16.5;
  static const double cardTitleFontSize = 19.5;
  static const double sectionTitleFontSize = 20.0;
  static const double vitalMetricFontSize = 29.0;

  static const Color callActionGreen = Color(0xFF1B7A43);
  static const Color callActionGreenSoft = Color(0xFFE7F6ED);
  static const Color warningAmberBg = Color(0xFFFFF6E5);
  static const Color warningAmberBorder = Color(0xFFE59A23);
  static const Color warningAmberText = Color(0xFF6E3F00);
  static const Color highBpRedBg = Color(0xFFFFEBEE);
  static const Color highBpRedText = Color(0xFFB71C1C);
}

/// Khối chức năng (Session) to, thoáng đãng, khoảng cách tối thiểu 24px,
/// tiêu đề 20px in đậm kèm icon 30px trực quan.
class SeniorSectionBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final Widget? trailing;
  final Widget child;
  final double bottomSpacing;

  const SeniorSectionBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.iconColor = AppColors.primary,
    this.iconBgColor,
    this.trailing,
    this.bottomSpacing = SeniorTokens.sectionGap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBgColor ?? iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: SeniorTokens.iconSize,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: SeniorTokens.sectionTitleFontSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.iceTextNavy,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.iceTextSlate,
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
          const SizedBox(height: AppLayoutTokens.sectionHeaderGap),
          child,
        ],
      ),
    );
  }
}

/// Thẻ nội dung chuẩn 40+: padding tối thiểu 18-20px, viền rõ nét, hỗ trợ bấm toàn thẻ.
class SeniorCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const SeniorCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SeniorTokens.cardPadding),
    this.backgroundColor = Colors.white,
    this.borderColor,
    this.borderWidth = 1.2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(SeniorTokens.cardRadius);
    final box = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? AppColors.iceCardBorder,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.iceTextNavy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
    return box;
  }
}

enum SeniorButtonVariant {
  primary,
  secondaryOutline,
  callNow,
  amberHighlight,
}

/// Nút bấm lớn chuẩn 40+ (chiều cao tối thiểu 54px >= 52px),
/// LUÔN đi kèm icon lớn (28px) và nhãn chữ tiếng Việt rõ ràng.
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
    final (bg, fg, border) = switch (variant) {
      SeniorButtonVariant.primary => (
          AppColors.primary,
          Colors.white,
          BorderSide.none,
        ),
      SeniorButtonVariant.callNow => (
          SeniorTokens.callActionGreen,
          Colors.white,
          BorderSide.none,
        ),
      SeniorButtonVariant.amberHighlight => (
          const Color(0xFFB86B11),
          Colors.white,
          BorderSide.none,
        ),
      SeniorButtonVariant.secondaryOutline => (
          Colors.white,
          AppColors.iceTextNavy,
          const BorderSide(color: AppColors.primary, width: 1.6),
        ),
    };

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        minimumSize: Size(expand ? double.infinity : 120, minHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: border,
        ),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
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

/// Nút phụ trên thanh tiêu đề (thay thế hoàn toàn các IconButton đứng một mình).
/// Luôn hiển thị Icon + Nhãn tiếng Việt dễ hiểu.
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
      color: backgroundColor ?? color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

/// Thẻ Lưới Tiện ích Sức khỏe lớn (Big Action Card) cho Trang chủ.
class SeniorBigGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const SeniorBigGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SeniorCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderColor: accentColor.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              size: SeniorTokens.iconSizeLarge,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.iceTextNavy,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.iceTextSlate,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Mở xem',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 20, color: accentColor),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ô tăng giảm chỉ số y tế chữ to (28px - 30px) với 2 nút [-] [+] cao 52px cực dễ bấm.
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
    this.accentColor = AppColors.primary,
  });

  Future<void> _openDirectInputDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: '$value');
    final typed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Nhập $label ($unit)',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            suffixText: unit,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 50),
            ),
            onPressed: () {
              final parsed = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, parsed);
            },
            child: const Text(
              'Xong',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.iceCardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.iceTextNavy,
                  ),
                ),
              ),
              Text(
                'Chạm số để gõ nhanh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StepIconBtn(
                icon: Icons.remove_rounded,
                semanticLabel: 'Giảm',
                onTap: value > min
                    ? () => onChanged((value - step).clamp(min, max))
                    : null,
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openDirectInputDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unit,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.iceTextSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _StepIconBtn(
                icon: Icons.add_rounded,
                semanticLabel: 'Tăng',
                onTap: value < max
                    ? () => onChanged((value + step).clamp(min, max))
                    : null,
              ),
            ],
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 56,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: AppColors.iceTextNavy),
              Text(
                semanticLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.iceTextSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh Bottom Navigation 4 mục tối đa chuẩn 40+: icon lớn (28px - 30px) + chữ tiếng Việt to rõ.
class SeniorBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  const SeniorBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
  });

  static const _items = [
    (icon: Icons.home_rounded, label: 'Trang chủ'),
    (icon: Icons.assignment_rounded, label: 'Bệnh án'),
    (icon: Icons.medication_rounded, label: 'Thuốc uống'),
    (icon: Icons.manage_accounts_rounded, label: 'Tài khoản'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final activeIdx = selectedIndex.clamp(0, _items.length - 1);

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding, top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.iceCardBorder, width: 1.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        height: 74,
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isSelected = i == activeIdx;
            final fgColor =
                isSelected ? AppColors.primaryDark : AppColors.iceTextSlate;

            return Expanded(
              child: InkWell(
                onTap: () => onSelectTab(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryPeach
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(
                          item.icon,
                          size: 29,
                          color: isSelected ? AppColors.primaryDark : fgColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: fgColor,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
